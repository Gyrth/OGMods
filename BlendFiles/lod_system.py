import bpy
from mathutils import *
import os.path
import re
from lxml import etree
import xml.etree.ElementTree as ET
from xml.etree.ElementTree import XMLParser
from pathlib import Path
from math import radians
from bpy.props import BoolProperty, IntVectorProperty, StringProperty, IntProperty
from bpy.types import (Panel, Operator)

bpy.types.Scene.og_path = StringProperty(subtype='DIR_PATH', name="Overgrowth Path")
bpy.types.Scene.level_path = StringProperty(subtype='FILE_PATH', name="Level Path")
bpy.types.Scene.import_plants = BoolProperty(name="Import Plants")
bpy.types.Scene.import_terrain = BoolProperty(name="Import Terrain")
bpy.types.Scene.draw_during_import = BoolProperty(name="Draw During Import")
bpy.types.Scene.terrain_size = IntProperty(name="Terrain Size", default=3072)
bpy.types.Scene.subdivide = IntProperty(name="Subdivide", default=3)
bpy.types.Scene.terrain_object = StringProperty(name="Terrain Object", subtype='BYTE_STRING')

load_models = True
draw_during_import = True
import_plants = False
import_terrain = False
terrain_size = 3072
subdivide = 3
terrain_object = ""
og_path = ""

def read_level_xml():
    nr_cubes = 2 ** subdivide
    cube_size = (terrain_size / nr_cubes)
    position_x = (-terrain_size / 2.0) + (cube_size / 2.0)
    position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    print(cube_size)
    terrain = bpy.data.objects[terrain_object]
    terrain_material = terrain.data.materials[0]
    
    for direction_x in range(nr_cubes):
        for direction_y in range(nr_cubes):
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            obj = bpy.context.object
            
            obj.scale = (cube_size, cube_size, 1000)
            obj.location = (position_x, position_y, 0)
            obj.name = "lod_" + str('%02d' % subdivide) + "_" + str(direction_x) + str(direction_y)
            
            boolmod = obj.modifiers.new("Bool", 'BOOLEAN')
            boolmod.operation = 'INTERSECT'
            boolmod.object = terrain
            obj.data.materials.append(terrain_material)
            if draw_during_import:
                bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
            print("Created LOD : " + obj.name)
            
            position_y += cube_size
        position_x += cube_size
        position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    print("Done creating LODs.")

def export_xml():
    # create the file structure
    object = ET.Element('Object')
    model = ET.SubElement(object, 'Model')
    colormap = ET.SubElement(object, 'ColorMap')
    normalmap = ET.SubElement(object, 'NormalMap')
    weightmap = ET.SubElement(object, 'WeightMap')
    detailmaps = ET.SubElement(object, 'DetailMaps')
    
    detailmap1 = ET.SubElement(detailmaps, 'DetailMap')
    detailmap2 = ET.SubElement(detailmaps, 'DetailMap')
    detailmap3 = ET.SubElement(detailmaps, 'DetailMap')
    detailmap4 = ET.SubElement(detailmaps, 'DetailMap')
    
    shadername = ET.SubElement(object, 'ShaderName')

    
    model.text = 'Data/Models/LODTerrain01.obj'
    colormap.text = 'Data/Textures/Terrain/impressive_mountains/impressive_mountains_c.tga'
    normalmap.text = 'Data/Textures/normal.tga'
    weightmap.text = 'Data/Textures/Terrain/impressive_mountains/impressive_mountains_w.png'
    
    detailmap1.set('colorpath','Data/Textures/Terrain/DetailTextures/snow.tga')
    shadername.text = 'envobject #DETAILMAP4 #TANGENT'

    resolved_write_directory = bpy.path.abspath(og_path + "test.xml")

    print("Path " + resolved_write_directory)

    # create a new XML file with the results
    mydata = ET.tostring(object).decode("utf-8")
    
    tree = etree.fromstring(mydata)
    pretty = etree.tostring(tree, encoding="unicode", pretty_print=True)
    
    myfile = open(resolved_write_directory, "w")
    print(pretty)
    myfile.write(pretty)

def read_terrain(og_path, terrain):
    if import_terrain and terrain != None:
        color_map = terrain.find("ColorMap").text
        terrain_path = terrain.find("Heightmap").text + ".obj"
        print("Loading terrain : " + terrain_path)
        
        if terrain.find("ModelOverride") != None:
            terrain_path = terrain.find("ModelOverride").text
        
        normal_path = terrain.find("Heightmap").text + "_normal.png"
        
        model = load_model(og_path, terrain_path, terrain_path, (0.0, 0.0, 0.0), (1.0, 1.0, 1.0), Quaternion(), False)
        create_material(og_path, color_map, model, [1.0, 1.0, 1.0, 1.0], False, normal_path, True)
        model.rotation_mode = 'XYZ'
        rotate_object(model, radians(90.0), (1.0, 0.0, 0.0), (0.0, 0.0, 0.0))

def read_body(og_path, root):
    list = find_child(root, "EnvObject")
    for child in list:
        extract_env_object(og_path, child, import_plants)

def find_child(root, tag):
    list = []
    for child in root:
        if child.tag == tag:
            list.append(child)
        list.extend(find_child(child, tag))
    return list

def get_from_object_xml(og_path, xml_path, tag):
    resolved_path = path_insensitive(og_path + xml_path)
    try:
        with open(resolved_path, 'r') as file:
            content = file.read()
            if content.split("\n")[0] != "<?xml version=\"1.0\" ?>":
                content = "<?xml version=\"1.0\" ?>\n" + content
            
            content = content.replace("scale=1", "scale=\"1\"")
            content = content.replace("scale=2", "scale=\"2\"")
            content = content.replace("scale=3", "scale=\"3\"")
            content = content.replace("no_collision=true", "no_collision=\"true\"")
            
#            print(xml_path)
            result = re.findall('(?s)<Object>.+?</Object>', content)
            
            root = ET.fromstring('\n'.join(result))
            
            return root.find(tag).text
    except IOError:
        print("Could not find " + path)
        return None

def extract_env_object(og_path, env_data, import_plants):
    map_scale = False
    xml_path = env_data.get('type_file')
    use_transparency = False

    shader_name = get_from_object_xml(og_path, xml_path, 'ShaderName')
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
    model_path = get_from_object_xml(og_path, xml_path, 'Model')
    color_map = get_from_object_xml(og_path, xml_path, 'ColorMap')
    normal_map = get_from_object_xml(og_path, xml_path, 'NormalMap')
    
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
        model = load_model(og_path, model_path, xml_path, position, scale, rotation, True)
        
        model['ShaderName'] = shader_name
        model['Model'] = model_path
        model['ColorMap'] = color_map
        model['NormalMap'] = normal_map
        
        if color_map != None and model != None:
            create_material(og_path, color_map, model, color, use_transparency, normal_map, use_tangent)
            
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

def get_image(path):
    resolved_path = path_insensitive(path)
    image = None
    if resolved_path != None and os.path.isfile(resolved_path):
        image = bpy.data.images.load(resolved_path, check_existing=True)
    else:
        resolved_path = path_insensitive(path + '_converted.dds')
        if resolved_path != None and os.path.isfile(resolved_path):
            image = bpy.data.images.load(resolved_path, check_existing=True)
        else:
            print("Could not find " + path)
    return image

def create_material(og_path, color_map, model, color, use_transparency, normal_path, use_tangent):
    if len(model.data.materials) > 0:
        return
    
    color_image = get_image(og_path + color_map)
    normal_image = get_image(og_path + normal_path)
    
    color_image.alpha_mode = "CHANNEL_PACKED"
    material = bpy.data.materials.new(name=color_map)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Specular'].default_value = 0.0
    
    color_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
    color_texture.image = color_image

    normal_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
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

def load_model(og_path, model_path, xml_path, position, scale, rotation, recenter):
    resolved_path = path_insensitive(og_path + model_path)
#    print(og_path + model_path)
    
    if resolved_path != None and os.path.isfile(resolved_path):
        if not load_models:
            return None
        
        if xml_path in cached_object_names:
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

def clear():
    objs = bpy.data.objects
    for obj in objs:
        if obj.name.find("lod") != -1:
            objs.remove(obj, do_unlink=True)

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

def path_insensitive(path):
    """
    Recursive part of path_insensitive to do the work.
    """
    
    path = path.replace("\\", "/")
    path = path.replace("/data/", "/Data/")

    if path == '' or os.path.exists(path):
        return path

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
        global draw_during_import
        global import_plants
        global import_terrain
        global terrain_size
        global subdivide
        global terrain_object        
        
        draw_during_import = context.scene.draw_during_import
        import_plants = context.scene.import_plants
        import_terrain = context.scene.import_terrain
        terrain_size = context.scene.terrain_size
        subdivide = context.scene.subdivide
        terrain_object = context.scene.terrain_object
        
        read_level_xml()
        return {'FINISHED'}

class ClearOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.clear"
    
    def execute(self, context):
        clear()
        return {'FINISHED'}

class ExportOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.export_xml"
    
    def execute(self, context):
        global og_path
        
        og_path = context.scene.og_path
        
        export_xml()
        return {'FINISHED'}

class OGLevelImport(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Overgrowth Level Import"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        layout.prop(context.scene, "og_path")
        layout.prop(context.scene, "level_path")
        layout.prop(context.scene, "import_plants")
        layout.prop(context.scene, "import_terrain")
        layout.prop(context.scene, "draw_during_import")
        layout.prop(context.scene, "terrain_size")
        layout.prop(context.scene, "subdivide")
        
        scene = context.scene
        layout.prop_search(scene, "terrain_object", scene, "objects", text="Terrain Object")
        
        row = layout.row()
        row.operator(ImportOperator.bl_idname, text="Import", icon="LIBRARY_DATA_DIRECT")
        row.operator(ClearOperator.bl_idname, text="Clear", icon="CANCEL")
        
        layout.operator(ExportOperator.bl_idname, text="Export")

def register():
    bpy.utils.register_class(OGLevelImport)
    bpy.utils.register_class(ClearOperator)
    bpy.utils.register_class(ImportOperator)
    bpy.types.Scene.terrain_object = bpy.props.StringProperty()
    bpy.types.Scene.og_path = bpy.props.StringProperty()
    bpy.utils.register_class(ExportOperator)

def unregister():
    bpy.utils.unregister_class(OGLevelImport)
    bpy.utils.unregister_class(ClearOperator)
    bpy.utils.unregister_class(ImportOperator)
    del bpy.types.Object.terrain_object
    del bpy.types.Object.og_path
    bpy.utils.unregister_class(ExportOperator)

if __name__ == "__main__":
    register()
else:
    print('starting addon')
    register()