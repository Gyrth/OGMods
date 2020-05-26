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

terrain_size = 3072
subdivide = 3
draw_during_import = True
load_models = True
export_xml = True
export_obj = True
terrain_object = ""
export_path = ""
colormap_path = "Data/Textures/Terrain/impressive_mountains/impressive_mountains_c.tga"
normalmap_path = "Data/Textures/normal.tga"
weightmap_path = "Data/Textures/Terrain/impressive_mountains/impressive_mountains_w.png"
shader = "envobject #DETAILMAP4 #TANGENT"

detailmap1_color = "Data/Textures/Terrain/DetailTextures/snow.tga"
detailmap1_normal = "Data/Textures/Terrain/DetailTextures/snow_normal.tga"
detailmap1_material = "Data/Materials/snow.xml"

detailmap2_color = "Data/Textures/Terrain/DetailTextures/glacial.tga"
detailmap2_normal = "Data/Textures/Terrain/DetailTextures/glacial_normal.tga"
detailmap2_material = "Data/Materials/ice.xml"

detailmap3_color = "Data/Textures/Terrain/DetailTextures/pebbles.tga"
detailmap3_normal = "Data/Textures/Terrain/DetailTextures/pebbles_normal.tga"
detailmap3_material = "Data/Materials/gravel.xml"

detailmap4_color = "Data/Textures/Terrain/DetailTextures/dark_round_rocks.tga"
detailmap4_normal = "Data/Textures/Terrain/DetailTextures/dark_round_rocks_normal.tga"
detailmap4_material = "Data/Materials/rocks.xml"

bpy.types.Scene.export_path = StringProperty(subtype='DIR_PATH', name="Export Path")
bpy.types.Scene.level_path = StringProperty(subtype='FILE_PATH', name="Level Path")
bpy.types.Scene.export_xml = BoolProperty(name="Export XML")
bpy.types.Scene.export_obj = BoolProperty(name="Export Model")
bpy.types.Scene.draw_during_import = BoolProperty(name="Draw During Import", default=draw_during_import)
bpy.types.Scene.terrain_size = IntProperty(name="Terrain Size", default=terrain_size)
bpy.types.Scene.subdivide = IntProperty(name="Subdivide", default=subdivide)
bpy.types.Scene.terrain_object = StringProperty(name="Terrain Object", subtype='BYTE_STRING')
bpy.types.Scene.colormap_path = StringProperty(name="ColorMap", default=colormap_path)
bpy.types.Scene.normalmap_path = StringProperty(name="NormalMap", default=normalmap_path)
bpy.types.Scene.weightmap_path = StringProperty(name="WeightMap", default=weightmap_path)
bpy.types.Scene.shader = StringProperty(name="ShaderName", default=shader)

bpy.types.Scene.detailmap1_color = StringProperty(name="1 DetailMap Color", default=detailmap1_color)
bpy.types.Scene.detailmap1_normal = StringProperty(name="1 DetailMap Normal", default=detailmap1_normal)
bpy.types.Scene.detailmap1_material = StringProperty(name="1 DetailMap Material", default=detailmap1_material)

bpy.types.Scene.detailmap2_color = StringProperty(name="2 DetailMap Color", default=detailmap2_color)
bpy.types.Scene.detailmap2_normal = StringProperty(name="2 DetailMap Normal", default=detailmap2_normal)
bpy.types.Scene.detailmap2_material = StringProperty(name="2 DetailMap Material", default=detailmap2_material)

bpy.types.Scene.detailmap3_color = StringProperty(name="3 DetailMap Color", default=detailmap3_color)
bpy.types.Scene.detailmap3_normal = StringProperty(name="3 DetailMap Normal", default=detailmap3_normal)
bpy.types.Scene.detailmap3_material = StringProperty(name="3 DetailMap Material", default=detailmap3_material)

bpy.types.Scene.detailmap4_color = StringProperty(name="4 DetailMap Color", default=detailmap4_color)
bpy.types.Scene.detailmap4_normal = StringProperty(name="4 DetailMap Normal", default=detailmap4_normal)
bpy.types.Scene.detailmap4_material = StringProperty(name="4 DetailMap Material", default=detailmap4_material)

def create_lods():
    create_lod(4, 2, 0.1)
#    create_lod(5, 1, 0.1)

def create_lod(lod_index, nr_subdivide, decimate_ratio):
    print("Creating LOD " + str(lod_index))
    
    nr_cubes = 2 ** nr_subdivide
    cube_size = (terrain_size / nr_cubes)
    position_x = (-terrain_size / 2.0) + (cube_size / 2.0)
    position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    terrain = bpy.data.objects[terrain_object]
    terrain_material = terrain.data.materials[0]
    
    set_decimate_ratio(terrain, decimate_ratio);
    
    lod_counter = 0
    
    for direction_x in range(nr_cubes):
        for direction_y in range(nr_cubes):
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            obj = bpy.context.object
            
            obj.scale = (cube_size, cube_size, 1000)
            obj.location = (position_x, position_y, 0)
            obj.name = "lod_" + str(lod_index) + "_" + str('%03d' % lod_counter)
            
            #Apply the same material to the newly created mesh as the terrain.
            obj.data.materials.append(terrain_material)
            
            apply_boolean(obj, terrain)
            
            #Update drawing the viewport to show progress.
            if draw_during_import:
                bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
            
            print("Created LOD : " + obj.name)
            
            bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
            
            if export_xml:
                export_lod_xml(obj)
            
            if export_obj:
                export_lod_obj(obj)
            
            position_y += cube_size
            lod_counter += 1
        position_x += cube_size
        position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    terrain.modifiers.remove(terrain.modifiers.get("Decimate"))
    
    print("Done creating LODs.")

def set_decimate_ratio(terrain, ratio):
    print("Setting decimate ratio " + str(ratio))
    
    decimatemod = terrain.modifiers.get("Decimate")
    if decimatemod is None:
        # otherwise add a modifier to selected object
        decimatemod = terrain.modifiers.new("Decimate", 'DECIMATE')
    
    decimatemod.ratio=ratio
    decimatemod.use_collapse_triangulate=True

def apply_boolean(obj, terrain):
    print("Applying boolean on " + obj.name)
    #Add a new boolean modifier.
    boolmod = obj.modifiers.new("Bool", 'BOOLEAN')
    #Make it an intersection boolean.
    boolmod.operation = 'INTERSECT'
    #Use the terrain object as the target to slice.
    boolmod.object = terrain
    
    #Apply the boolean modifier.
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=boolmod.name)

def export_lod_obj(obj):
    bpy.context.view_layer.objects.active = obj
    resolved_write_directory = bpy.path.abspath(export_path + "Data/Models/" + terrain_object + "/" + obj.name + ".obj")
    
    #Create the directories if they do not exist.
    if not os.path.exists(os.path.dirname(resolved_write_directory)):
        try:
            os.makedirs(os.path.dirname(resolved_write_directory))
        except OSError as exc: # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise
    
    bpy.ops.export_scene.obj(filepath=resolved_write_directory, use_selection=True, use_materials=False, axis_forward='X')
    print("Exported model " + resolved_write_directory)

def export_lod_xml(obj):
    lod_name = obj.name
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
    label = ET.SubElement(object, 'label')
    
    model.text = 'Data/Models/' + terrain_object + "/" + lod_name + '.obj'
    colormap.text = colormap_path
    normalmap.text = normalmap_path
    weightmap.text = weightmap_path
    
    detailmap1.set('colorpath', detailmap1_color)
    detailmap1.set('normalpath', detailmap1_normal)
    detailmap1.set('materialpath', detailmap1_material)
    
    detailmap2.set('colorpath', detailmap2_color)
    detailmap2.set('normalpath', detailmap2_normal)
    detailmap2.set('materialpath', detailmap2_material)
    
    detailmap3.set('colorpath', detailmap3_color)
    detailmap3.set('normalpath', detailmap3_normal)
    detailmap3.set('materialpath', detailmap3_material)
    
    detailmap4.set('colorpath', detailmap4_color)
    detailmap4.set('normalpath', detailmap4_normal)
    detailmap4.set('materialpath', detailmap4_material)
    
    shadername.text = shader
    label.text = str(obj.location.z)

    resolved_write_directory = bpy.path.abspath(export_path + "Data/Objects/" + terrain_object + "/" + lod_name + ".xml")

    # create a new XML file with the results
    mydata = ET.tostring(object).decode("utf-8")
    
    tree = etree.fromstring(mydata)
    pretty = "<?xml version=\"1.0\" ?>\n" + etree.tostring(tree, encoding="unicode", pretty_print=True)
    
    if not os.path.exists(os.path.dirname(resolved_write_directory)):
        try:
            os.makedirs(os.path.dirname(resolved_write_directory))
        except OSError as exc: # Guard against race condition
            if exc.errno != errno.EEXIST:
                raise
    
    myfile = open(resolved_write_directory, "w")
    myfile.write(pretty)
    
    print("Exported XML " + resolved_write_directory)

def clear():
    objs = bpy.data.objects
    for obj in objs:
        if obj.name.find("lod") != -1:
            objs.remove(obj, do_unlink=True)
    
    terrain = bpy.data.objects[terrain_object]
    for block in bpy.data.meshes:
        if terrain.data != block:
            bpy.data.meshes.remove(block)
    
    bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)

class CreateLODsOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.create_lods"
    
    def execute(self, context):
        global draw_during_import
        global export_xml
        global export_obj
        global terrain_size
        global subdivide
        global terrain_object
        global export_path
        global colormap_path
        global normalmap_path
        global weightmap_path
        global shader
        
        global detailmap1_color
        global detailmap1_normal
        global detailmap1_material
        
        global detailmap2_color
        global detailmap2_normal
        global detailmap2_material
        
        global detailmap3_color
        global detailmap3_normal
        global detailmap3_material
        
        global detailmap4_color
        global detailmap4_normal
        global detailmap4_material
        
        draw_during_import = context.scene.draw_during_import
        export_xml = context.scene.export_xml
        export_obj = context.scene.export_obj
        terrain_size = context.scene.terrain_size
        subdivide = context.scene.subdivide
        terrain_object = context.scene.terrain_object
        export_path = context.scene.export_path
        colormap_path = context.scene.colormap_path
        normalmap_path = context.scene.normalmap_path
        weightmap_path = context.scene.weightmap_path
        shader = context.scene.shader
        
        create_lods()
        return {'FINISHED'}

class ClearOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.clear"
    
    def execute(self, context):
        global terrain_object
        
        terrain_object = context.scene.terrain_object
        
        clear()
        return {'FINISHED'}

class CreateLODsPanel(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Create LODs"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        layout.prop(context.scene, "export_path")
#        layout.prop(context.scene, "level_path")
        layout.prop(context.scene, "export_xml")
        layout.prop(context.scene, "export_obj")
        layout.prop(context.scene, "draw_during_import")
        layout.prop(context.scene, "terrain_size")
#        layout.prop(context.scene, "subdivide")
        
        layout.prop(context.scene, "colormap_path")
        layout.prop(context.scene, "normalmap_path")
        layout.prop(context.scene, "weightmap_path")
        layout.prop(context.scene, "shader")
        
        layout.prop(context.scene, "detailmap1_color")
        layout.prop(context.scene, "detailmap1_normal")
        layout.prop(context.scene, "detailmap1_material")
        
        layout.prop(context.scene, "detailmap2_color")
        layout.prop(context.scene, "detailmap2_normal")
        layout.prop(context.scene, "detailmap2_material")
        
        layout.prop(context.scene, "detailmap3_color")
        layout.prop(context.scene, "detailmap3_normal")
        layout.prop(context.scene, "detailmap3_material")
        
        layout.prop(context.scene, "detailmap4_color")
        layout.prop(context.scene, "detailmap4_normal")
        layout.prop(context.scene, "detailmap4_material")
        
        scene = context.scene
        layout.prop_search(scene, "terrain_object", scene, "objects", text="Terrain Object")
        
        row = layout.row()
        row.operator(CreateLODsOperator.bl_idname, text="Create", icon="LIBRARY_DATA_DIRECT")
        row.operator(ClearOperator.bl_idname, text="Clear", icon="CANCEL")

def register():
    bpy.utils.register_class(CreateLODsOperator)
    bpy.utils.register_class(ClearOperator)
    bpy.utils.register_class(CreateLODsPanel)
    bpy.types.Scene.terrain_object = bpy.props.StringProperty()

def unregister():
    bpy.utils.unregister_class(CreateLODsOperator)
    bpy.utils.unregister_class(ClearOperator)
    bpy.utils.unregister_class(CreateLODsPanel)
    del bpy.types.Object.terrain_object

if __name__ == "__main__":
    register()
else:
    print('starting addon')
    register()