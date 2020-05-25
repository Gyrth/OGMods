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
operator = ""

def create_lods():
    create_lod(5, 1, 0.1)

def create_lod(lod_index, nr_subdivide, decimate_ratio):
    print("Creating LOD " + str(lod_index))
    
    operator.report({'INFO'}, 'Printing report to Info window.')
    
    nr_cubes = 2 ** nr_subdivide
    cube_size = (terrain_size / nr_cubes)
    position_x = (-terrain_size / 2.0) + (cube_size / 2.0)
    position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    terrain = bpy.data.objects[terrain_object]
    terrain_material = terrain.data.materials[0]
    
    lod_counter = 0
    
    for direction_x in range(nr_cubes):
        for direction_y in range(nr_cubes):
            bpy.ops.mesh.primitive_cube_add(size=1.0)
            obj = bpy.context.object
            
            obj.scale = (cube_size, cube_size, 1000)
            obj.location = (position_x, position_y, 0)
            obj.name = "lod_" + str(lod_index) + "_" + str('%02d' % lod_counter)
            
            #Apply the same material to the newly created mesh as the terrain.
            obj.data.materials.append(terrain_material)
            
            apply_boolean(obj, terrain)
            apply_decimate(obj, decimate_ratio);
            
            #Update drawing the viewport to show progress.
            if draw_during_import:
                bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
            
            print("Created LOD : " + obj.name)
            
            export_xml(obj.name)
            export_model(obj)
            
            position_y += cube_size
            lod_counter += 1
        position_x += cube_size
        position_y = (-terrain_size / 2.0) + (cube_size / 2.0)
    
    print("Done creating LODs.")

def apply_decimate(obj, ratio):
    print("Applying decimate on " + obj.name)
    #Add a new decimate modifier.
    decimatemod = obj.modifiers.new('Decimate','DECIMATE')
    decimatemod.ratio=ratio
    decimatemod.use_collapse_triangulate=True
    
    #Apply the decimate modifier.
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=decimatemod.name)

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

def export_model(obj):
    bpy.context.view_layer.objects.active = obj
    resolved_write_directory = bpy.path.abspath(og_path + "Data/Models/" + obj.name + ".obj")
    bpy.ops.export_scene.obj(filepath=resolved_write_directory, use_selection=True, use_materials=False)
    print("Exported model " + "Data/Models/" + obj.name + ".obj")

def export_xml(lod_name):
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
    
    model.text = 'Data/Models/' + lod_name + '.obj'
    colormap.text = 'Data/Textures/Terrain/impressive_mountains/impressive_mountains_c.tga'
    normalmap.text = 'Data/Textures/normal.tga'
    weightmap.text = 'Data/Textures/Terrain/impressive_mountains/impressive_mountains_w.png'
    
    detailmap1.set('colorpath','Data/Textures/Terrain/DetailTextures/snow.tga')
    shadername.text = 'envobject #DETAILMAP4 #TANGENT'

    resolved_write_directory = bpy.path.abspath(og_path + "Data/Objects/" + lod_name + ".xml")

    # create a new XML file with the results
    mydata = ET.tostring(object).decode("utf-8")
    
    tree = etree.fromstring(mydata)
    pretty = "<?xml version=\"1.0\" ?>\n" + etree.tostring(tree, encoding="unicode", pretty_print=True)
    
    myfile = open(resolved_write_directory, "w")
    myfile.write(pretty)
    
    print("Exported XML " + resolved_write_directory)

def clear():
    objs = bpy.data.objects
    for obj in objs:
        if obj.name.find("lod") != -1:
            objs.remove(obj, do_unlink=True)

    bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)

class CreateLODsOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.create_lods"
    
    def execute(self, context):
        global draw_during_import
        global import_plants
        global import_terrain
        global terrain_size
        global subdivide
        global terrain_object
        global og_path
        global operator
        
        draw_during_import = context.scene.draw_during_import
        import_plants = context.scene.import_plants
        import_terrain = context.scene.import_terrain
        terrain_size = context.scene.terrain_size
        subdivide = context.scene.subdivide
        terrain_object = context.scene.terrain_object
        og_path = context.scene.og_path
        operator = self
        
        create_lods()
        return {'FINISHED'}

class ClearOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.clear"
    
    def execute(self, context):
        clear()
        return {'FINISHED'}

class CreateLODsPanel(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Create LODs"
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