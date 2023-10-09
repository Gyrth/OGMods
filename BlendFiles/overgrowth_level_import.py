import bpy
from mathutils import *
import os.path
import re
import xml.etree.ElementTree as ET
from xml.etree.ElementTree import XMLParser
from pathlib import Path
from math import radians
from bpy.props import BoolProperty, IntVectorProperty, StringProperty
from bpy.types import (Panel, Operator)

bpy.types.Scene.og_path = StringProperty(subtype='DIR_PATH', name="Overgrowth Path")
bpy.types.Scene.workshop_path = StringProperty(subtype='FILE_PATH', name="Workshop Path")
bpy.types.Scene.level_path = StringProperty(subtype='FILE_PATH', name="Level Path")
bpy.types.Scene.import_plants = BoolProperty(name="Import Plants")
bpy.types.Scene.import_terrain = BoolProperty(name="Import Terrain")
bpy.types.Scene.draw_during_import = BoolProperty(name="Draw During Import")
bpy.types.Scene.create_materials = BoolProperty(name="Create Materials")

load_models = True
draw_during_import = True
import_plants = False
import_terrain = False
create_materials = True

cached_object_names = []
cached_object_meshes = []

def read_level_xml(og_path, workshop_path, level_path, info):
    with open(level_path, 'r') as file:
        content = file.read()
        content = content.replace("<?xml version=\"2.0\" ?>\n", "")
        root = ET.fromstring("<data>" + content + "</data>")
        
        skydome_path = root.find("Sky").find("DomeTexture").text
        
        world = bpy.context.scene.world
        node_tree = bpy.data.worlds[world.name].node_tree
        env_texture = node_tree.nodes["Environment Texture"]
        img = None
        
        resolved_path = get_asset_path(skydome_path, og_path, workshop_path)
        if resolved_path != None and os.path.isfile(resolved_path):
            img = bpy.data.images.load(resolved_path, check_existing=True)
        else:
            resolved_path = get_asset_path(skydome_path + '_converted.dds', og_path, workshop_path)
            if resolved_path != None and os.path.isfile(resolved_path):
                img = bpy.data.images.load(resolved_path, check_existing=True)
            else:
                print("Could not find " + skydome_path)
                return
        env_texture.image = img
        
        read_terrain(og_path, workshop_path, root.find("Terrain"))
        read_body(og_path, workshop_path, root, info)

def read_terrain(og_path, workshop_path, terrain):
    if import_terrain and terrain != None:
        color_map = terrain.find("ColorMap").text
        terrain_path = terrain.find("Heightmap").text + ".obj"
        print("Loading terrain : " + terrain_path)
        
        if terrain.find("ModelOverride") != None:
            terrain_path = terrain.find("ModelOverride").text
        
        normal_path = terrain.find("Heightmap").text + "_normal.png"
        
        model = load_model(og_path, workshop_path, terrain_path, terrain_path, (0.0, 0.0, 0.0), (1.0, 1.0, 1.0), Quaternion(), False)
        create_material(og_path, workshop_path, color_map, model, [1.0, 1.0, 1.0, 1.0], False, normal_path, True)
        model.rotation_mode = 'XYZ'
        rotate_object(model, radians(90.0), (1.0, 0.0, 0.0), (0.0, 0.0, 0.0))

def read_body(og_path, workshop_path, root, info):
    list = find_child(root, "EnvObject")
    for child in list:
        print("Loading object : " + str(list.index(child)) + "/" + str(len(list)))
        extract_env_object(og_path, workshop_path, child, import_plants, info)

def find_child(root, tag):
    list = []
    for child in root:
        if child.tag == tag:
            list.append(child)
        list.extend(find_child(child, tag))
    return list

def get_from_object_xml(xml_path, og_path, workshop_path, tag, info):
    resolved_path = get_asset_path(xml_path, og_path, workshop_path)
    
    if resolved_path is None:
        check = str(Path(og_path + xml_path).resolve())
        print("resolved_path " + check)
        info.report({'WARNING'}, "Couldn't resolve : " + xml_path)
        
        return None
    
    try:
        with open(resolved_path, 'r') as file:
            content = file.read()
            if content.split("\n")[0] != "<?xml version=\"1.0\" ?>":
                content = "<?xml version=\"1.0\" ?>\n" + content
            
            content = re.sub('scale=\S+', '', content)
            content = content.replace("no_collision=true", "no_collision=\"true\"")
            
#            print(resolved_path + " tag " + tag)
            result = re.findall('(?s)<Object>.+?</Object>', content)
            
            root = ET.fromstring('\n'.join(result))
            
            return root.find(tag).text
    except IOError:
        print("Could not find " + path)
        return None

def extract_env_object(og_path, workshop_path, env_data, import_plants, info):
    map_scale = False
    xml_path = env_data.get('type_file')
    use_transparency = False

    shader_name = get_from_object_xml(xml_path, og_path, workshop_path, 'ShaderName', info)
    if shader_name == None:
        return
    elif 'cubemapalpha' in shader_name:
      use_transparency = True
    elif 'plant' in shader_name or 'PLANT' in shader_name:
        if not import_plants:
            print("Not loading " + xml_path)
            return
        else:
            use_transparency = True
    if 'detailmap4tangent' in shader_name:
        map_scale = True
    
    use_tangent = "TANGENT" in shader_name or shader_name == "cubemap" or shader_name == "plant" or shader_name == "plant_less_movement" or shader_name == "plant_foliage" or shader_name == "detailmap4tangent"
    model_path = get_from_object_xml(xml_path, og_path, workshop_path, 'Model', info)
    color_map = get_from_object_xml(xml_path, og_path, workshop_path, 'ColorMap', info)
    normal_map = get_from_object_xml(xml_path, og_path, workshop_path, 'NormalMap', info)
    
    print("Loading xml : " + xml_path)

    if model_path != None:
        scale = Vector((get_float(env_data, 's0'), get_float(env_data, 's1'), get_float(env_data, 's2')))
        position = Vector((get_float(env_data, 't0'), get_float(env_data, 't1'), get_float(env_data, 't2')))
        rotation = Quaternion()
        
        if env_data.get('q3') == None or env_data.get('q0') == None:
            list1 = [get_float(env_data, 'r0'), get_float(env_data, 'r4'), get_float(env_data, 'r8')]
            list2 = [get_float(env_data, 'r1'), get_float(env_data, 'r5'), get_float(env_data, 'r9')]
            list3 = [get_float(env_data, 'r2'), get_float(env_data, 'r6'), get_float(env_data, 'r10')]
            
            rotation_matrix = Matrix((list1, list2, list3))
            rotation = rotation_matrix.to_quaternion()
        else:
            rotation = Quaternion((get_float(env_data, 'q3'), get_float(env_data, 'q0'), get_float(env_data, 'q1'), get_float(env_data, 'q2')))

        color = Vector((get_float(env_data, 'color_r'), get_float(env_data, 'color_g'), get_float(env_data, 'color_b'), 1.0))
        model = load_model(og_path, workshop_path, model_path, xml_path, position, scale, rotation, True)
        
        model['ShaderName'] = shader_name
        model['Model'] = model_path
        model['ColorMap'] = color_map
        model['NormalMap'] = normal_map
        
        if color_map != None and model != None:
            create_material(og_path, workshop_path, color_map, model, color, use_transparency, normal_map, use_tangent)
            model.rotation_mode = 'XYZ'
            rotate_object(model, radians(90.0), (1.0, 0.0, 0.0), (0.0, 0.0, 0.0))
            if draw_during_import:
                bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
    else:
        raise TypeError('Could not get model path : ' + model_path)

def get_float(data, key):
    if data.get(key) != None:
        return float(data.get(key))
    else:
        return 1.0
#        raise TypeError('Unable to get : ' + key)

def get_image(path, og_path, workshop_path):
    resolved_path = get_asset_path(path, og_path, workshop_path)
    image = None
    if resolved_path != None and os.path.isfile(resolved_path):
        image = bpy.data.images.load(resolved_path, check_existing=True)
    else:
        resolved_path = get_asset_path(path + '_converted.dds', og_path, workshop_path)
        if resolved_path != None and os.path.isfile(resolved_path):
            image = bpy.data.images.load(resolved_path, check_existing=True)
        else:
            print("Could not find " + path)
    return image

def create_material(og_path, workshop_path, color_map, model, color, use_transparency, normal_path, use_tangent):
    if not create_materials or len(model.data.materials) > 0:
        return
    
    color_image = get_image(color_map, og_path, workshop_path)
    normal_image = get_image(normal_path, og_path, workshop_path)
    
    color_image.alpha_mode = "CHANNEL_PACKED"
    material = bpy.data.materials.new(name=color_map)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Specular'].default_value = 0.0
    
    color_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
    color_texture.image = color_image

    normal_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
    if normal_image != None:
        normal_image.colorspace_settings.name = 'Non-Color'
    normal_texture.image = normal_image

    # Assign it to object
    if model.data.materials:
        model.data.materials[0] = material
    else:
        model.data.materials.append(material)
    
    rgbmix = material.node_tree.nodes.new('ShaderNodeMixRGB')
    rgbmix.blend_type = "MULTIPLY"
    rgbmix.inputs["Fac"].default_value = 1.0
    rgbmix.inputs["Color2"].default_value = color
    material.node_tree.links.new(color_texture.outputs['Color'], rgbmix.inputs['Color1'])
    material.node_tree.links.new(rgbmix.outputs['Color'], bsdf.inputs['Base Color'])
    
    normalmap = material.node_tree.nodes.new('ShaderNodeNormalMap')
    if use_tangent:
        normalmap.space = "TANGENT"
        material.node_tree.links.new(normal_texture.outputs['Color'], normalmap.inputs['Color'])
    else:
        normalmap.space = "OBJECT"
        invert_green = material.node_tree.nodes.new('ShaderNodeInvert')
        separatergb = material.node_tree.nodes.new('ShaderNodeSeparateRGB')
        combinergb = material.node_tree.nodes.new('ShaderNodeCombineRGB')
        
        material.node_tree.links.new(normal_texture.outputs['Color'], separatergb.inputs['Image'])
        material.node_tree.links.new(separatergb.outputs['R'], combinergb.inputs['R'])
        material.node_tree.links.new(separatergb.outputs['G'], invert_green.inputs['Color'])
        material.node_tree.links.new(invert_green.outputs['Color'], combinergb.inputs['B'])
        material.node_tree.links.new(separatergb.outputs['B'], combinergb.inputs['G'])
        
        material.node_tree.links.new(combinergb.outputs['Image'], normalmap.inputs['Color'])
    
    if normal_image != None:
        material.node_tree.links.new(normalmap.outputs['Normal'], bsdf.inputs['Normal'])
    
    invert = material.node_tree.nodes.new('ShaderNodeInvert')
    material.node_tree.links.new(color_texture.outputs['Alpha'], invert.inputs['Color'])
    material.node_tree.links.new(invert.outputs['Color'], bsdf.inputs['Roughness'])
    
    if use_transparency:
        material.blend_method = "HASHED"
        material.shadow_method = "HASHED"
        material.node_tree.links.new(color_texture.outputs['Alpha'], bsdf.inputs['Alpha'])
#        bsdf.inputs['Alpha'].default_value = texImage
        pass
    else:
#        img.use_alpha = False
        pass

def load_model(og_path, workshop_path, model_path, xml_path, position, scale, rotation, recenter):
    resolved_path = get_asset_path(model_path, og_path, workshop_path)
#    print(og_path + model_path)
    
    if resolved_path != None and os.path.isfile(resolved_path):
        if not load_models:
            return None
        
        use_cache = True
        if xml_path in cached_object_names and use_cache:
            target_object = cached_object_meshes[cached_object_names.index(xml_path)]
            for obj in bpy.context.selected_objects[:]:
                obj.select_set(False)
            target_object.select_set(True)
            duplicate = bpy.ops.object.duplicate(linked=True)
            
#            return None
        else:
            imported_object = bpy.ops.import_scene.obj(filepath=resolved_path)
            obj_objects = bpy.context.selected_objects[:]
            cached_object_names.append(xml_path)
            cached_object_meshes.append(obj_objects[0])
            obj_objects[0].data.materials.clear()
        
            obj_objects = bpy.context.selected_objects[:]
            
            if recenter:
                bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
            for obj in obj_objects:
                obj.name = Path(xml_path).name
                obj.data.name = Path(resolved_path).name
                obj.select_set(True)
            if len(obj_objects) > 1:
                bpy.context.scene.objects.active = obj_objects[0]
                bpy.ops.object.join()
        
        obj = bpy.context.selected_objects[0]
        obj.scale = scale
        obj.location = position
        obj.rotation_mode = 'QUATERNION'
        obj.rotation_quaternion = rotation
                
        return bpy.context.selected_objects[0]
    else:
        raise TypeError('Could not find model : ' + model_path)
        return None

def rotate_object(obj, angle, direction, point):
    R = Matrix.Rotation(angle, 4, direction)
    T = Matrix.Translation(point)
    M = T @ R @ T.inverted()
    obj.location = M @ obj.location
    obj.rotation_euler.rotate(M)

def rotate_all():
    objects = bpy.context.scene.objects
    for obj in objects:
        obj.select = False

    for obj in objects:
        obj.rotation_mode = 'XYZ'
        rotate_object(obj, radians(90.0), (1.0, 0.0, 0.0), (0.0, 0.0, 0.0))

def combine_all():
    objects = bpy.context.scene.objects
    for obj in objects:
        obj.select = True
    bpy.context.scene.objects.active = objects[0]
    bpy.ops.object.join()

def bake_texture():
    colormap_image = bpy.data.images.new("colormap", width=4096, height=4096)
    normalmap_image = bpy.data.images.new("normalmap", width=4096, height=4096)
    
    obj = bpy.context.scene.objects[0]
    bpy.context.scene.objects.active = obj
    
    baked_uv = obj.data.uv_textures.new(name='BakedUV')
    obj.data.uv_textures.active = baked_uv
    
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.uv.smart_project(angle_limit = 66.0, island_margin = 0.02)
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    for face in baked_uv.data:
        face.image = normalmap_image
    
    bpy.ops.object.mode_set(mode='EDIT')
    
    bpy.context.scene.render.bake_type = 'NORMALS'
    bpy.context.scene.render.bake_margin = 16
    bpy.context.scene.render.bake_normal_space = 'OBJECT'   
    #bpy.ops.object.bake_image()
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    uv_tex = obj.data.uv_textures.active.data
    for face in uv_tex:
        face.image = colormap_image
    
    bpy.ops.object.mode_set(mode='EDIT')
        
    bpy.context.scene.render.bake_type = 'TEXTURE'
    bpy.context.scene.render.bake_margin = 16
    bpy.ops.object.bake_image()
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    #image.filepath_raw = "/tmp/temp.png"
    #image.file_format = 'PNG'
    #image.save()

def clear(info):
    objs = bpy.data.objects
    for obj in objs:
        if obj.type != 'LIGHT' and obj.type != 'CAMERA':
            objs.remove(obj, do_unlink=True)
    
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    
    for m in bpy.data.materials:
        bpy.data.materials.remove(m)
    
    for img in bpy.data.images:
        bpy.data.images.remove(img)
    
    cached_object_names.clear()
    cached_object_meshes.clear()
    bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)

def decimate_all():
    THR = 4  # <-- the only parameter. The smaller, the stricter
    for element in bpy.data.objects:
        if element.type != "MESH": continue

        # reset
        for m in element.modifiers:
            if m.name == 'ScriptedDecimate':
                element.modifiers.remove(m)

        # scoring function
        vert = len(element.data.vertices)
        areabbox = (element.dimensions.x*element.dimensions.y
                   + element.dimensions.y*element.dimensions.z
                   + element.dimensions.x*element.dimensions.z)*2
        indicator = vert/areabbox

        # select and decimate!
        if (indicator > THR):
            element.select=True
            decimator = element.modifiers.new("ScriptedDecimate", type = "DECIMATE")
            decimator.ratio = (THR/indicator)**(2/3)
            bpy.context.scene.update()
            bpy.context.scene.objects.active = element
            for modifier in element.modifiers:
                bpy.ops.object.modifier_apply(modifier=modifier.name)
        else:
            element.select=False

def get_asset_path(path, og_path, workshop_path):
    if path == '':
        return None
    
    resolved_path = path_insensitive(og_path + path)
    
    if resolved_path != None and os.path.exists(resolved_path):
        return resolved_path
    
    workshop_folders = os.listdir(workshop_path)
    for mod_folder in workshop_folders:
        resolved_path = path_insensitive(workshop_path + mod_folder + "/" + path)
        if resolved_path != None and os.path.exists(resolved_path):
            return resolved_path

    return None

def path_insensitive(path):
    base = os.path.basename(path)  # may be a directory or a file
    dirname = os.path.dirname(path)

    suffix = ''
    if not base:  # dir ends with a slash?
        if len(dirname) < len(path):
            suffix = path[:len(path) - len(dirname)]

        base = os.path.basename(dirname)
        dirname = os.path.dirname(dirname)

    if not os.path.exists(dirname):
        dirname = path_insensitive(dirname)
        if not dirname:
            return

    # at this point, the directory exists but not the file

    try:  # we are expecting dirname to be a directory, but it could be a file
        files = os.listdir(dirname)
    except OSError:
        return
    
    baselow = base.lower()
    try:
        basefinal = next(fl for fl in files if fl.lower() == baselow)
        
    except StopIteration:
        return

    if basefinal:
        return os.path.join(dirname, basefinal) + suffix
    else:
        return

class ImportOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.import"
    
    def execute(self, context):
        clear(self)
        global draw_during_import
        global import_plants
        global import_terrain
        global create_materials
        
        draw_during_import = context.scene.draw_during_import
        import_plants = context.scene.import_plants
        import_terrain = context.scene.import_terrain
        create_materials = context.scene.create_materials
        
        resolved_og_path = str(Path(context.scene.og_path).resolve()) + "/"
        resolved_workshop_path = str(Path(context.scene.workshop_path).resolve()) + "/"
        resolved_level_path = str(Path(context.scene.level_path).resolve())
        
        print(resolved_og_path)
        print(resolved_workshop_path)
        print(resolved_level_path)
        
        read_level_xml(resolved_og_path, resolved_workshop_path, resolved_level_path, self)
        return {'FINISHED'}

class ClearOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.clear"
    
    def execute(self, context):
        clear(self)
        return {'FINISHED'}

class OGLevelImport(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Overgrowth Level Import"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        self.layout.prop(context.scene, "og_path")
        self.layout.prop(context.scene, "workshop_path")
        self.layout.prop(context.scene, "level_path")
        self.layout.prop(context.scene, "import_plants")
        self.layout.prop(context.scene, "import_terrain")
        self.layout.prop(context.scene, "draw_during_import")
        self.layout.prop(context.scene, "create_materials")
        
        row = layout.row()
        row.operator(ImportOperator.bl_idname, text="Import", icon="LIBRARY_DATA_DIRECT")
        row.operator(ClearOperator.bl_idname, text="Clear", icon="CANCEL")

def register():
    bpy.utils.register_class(OGLevelImport)
    bpy.utils.register_class(ClearOperator)
    bpy.utils.register_class(ImportOperator)

def unregister():
    bpy.utils.unregister_class(OGLevelImport)
    bpy.utils.unregister_class(ClearOperator)
    bpy.utils.unregister_class(ImportOperator)

if __name__ == "__main__":
    register()
else:
    print('starting addon')
    register()