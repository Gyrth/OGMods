import bpy
from mathutils import *
import os.path
from os import walk
import re
import xml.etree.ElementTree as ET
import lxml.etree as etree
from xml.etree.ElementTree import XMLParser
from pathlib import Path
from math import radians
from bpy.props import BoolProperty, IntVectorProperty, StringProperty
from bpy.types import (Panel, Operator)
import random
from xml.etree import ElementTree
from xml.dom import minidom
from shutil import copyfile

bpy.types.Scene.import_path = StringProperty(subtype='DIR_PATH', name="Import Path")
bpy.types.Scene.export_path = StringProperty(subtype='FILE_PATH', name="Export Path")
bpy.types.Scene.export_xml = BoolProperty(name="Export XML")
bpy.types.Scene.export_thumbnails = BoolProperty(name="Export Thumbnails")
bpy.types.Scene.export_model = BoolProperty(name="Export Model")
bpy.types.Scene.export_texture = BoolProperty(name="Export Texture")

load_models = True
export_model = True
export_xml = False
export_thumbnails = False
export_texture = True

cached_object_names = []
cached_object_meshes = []
#plant_names = ["tree_large", "tree_shrub", "tree_small", "treePine_small", "treePine_large", "balconyLadder_bottom", "balconyLadder_top", "balcony_typeA"]
plant_names = ["fenceStraight", "fenceCurved"]
double_sided_names = []

def get_models(import_path, export_path, info):
    
    split_path = import_path.split("/")
    category_name = split_path[len(split_path) - 2]
    resolved_export_path = bpy.path.abspath(export_path)
    resolved_import_path = bpy.path.abspath(import_path + "Models/OBJ format")
    resolved_thumbnail_path = bpy.path.abspath(import_path + "Isometric")
    print("Import path : ", resolved_import_path)
    print("Export path : ", resolved_export_path)
    print("Category name : ", category_name)
    
#    f = ["tree_large.obj"]
    f = []
    for (dirpath, dirnames, filenames) in walk(resolved_import_path):
        f.extend(filenames)
        break

#    random.shuffle(f)

    root = minidom.Document()
    xml = root.createElement('root')
    root.appendChild(xml)
    
    #Import all the obj files.
    for model_path in f:
        if model_path[-3:] == 'obj':
            model_name = model_path[:len(model_path) - 4]
            print("Model name : " + model_name)
            imported_object = bpy.ops.import_scene.obj(filepath=resolved_import_path + "/" + model_path)
            obj_objects = bpy.context.selected_objects[:]
            
            object_xml_root = minidom.Document()
            object_xml = object_xml_root.createElement('Object')
            object_xml_root.appendChild(object_xml)
            
            #Create a texture to bake to.
            bpy.ops.image.new(name="bake", width=1024, height=1024, color=(0.0, 0.0, 0.0, 0.0), alpha=True, generated_type='BLANK', float=False, use_stereo_3d=False)
            bake_image = bpy.data.images['bake']
            
            for area in bpy.context.screen.areas :
                if area.type == 'IMAGE_EDITOR' :
                    area.spaces.active.image = bake_image
            
            for obj in obj_objects:
                for material in obj.data.materials:
                    material.use_nodes = True
                    
                    for node in material.node_tree.nodes:
                        if node.type == "TEX_IMAGE":
                            node.interpolation = 'Closest'
                    
                    bake_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
                    bake_texture.image = bake_image
                    bake_texture.interpolation = 'Closest'
                    
                    bsdf = material.node_tree.nodes["Principled BSDF"]
                    bsdf.inputs['Alpha'].default_value = 1.0
                    
                    nodes = material.node_tree.nodes
                    nodes.active = bake_texture
            
            obj.select_set(True)
            obj = obj_objects[0]
            bpy.context.view_layer.objects.active = obj
            obj.scale = (8.0, 8.0, 8.0)
            
            baked_uv = obj.data.uv_layers.new(name='BakedUV')
            obj.data.uv_layers.active = baked_uv
            
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.select_all(action='SELECT')
            
            #Create a new smart uv map for the new texture.
            bpy.ops.mesh.remove_doubles(threshold=0.0001)
            #The angle limit is done in radians not degrees.
            bpy.ops.uv.smart_project(angle_limit = 1.1519, island_margin = 0.01)
            
            #Now bake the colors and textures from all the materials into one.
            bpy.ops.object.bake(type='DIFFUSE', save_mode='INTERNAL')
            
            bpy.ops.object.mode_set(mode='OBJECT')
            
            #Export the newly created image.
            if export_texture:
                image_export_path = resolved_export_path + "/Textures/kenney/" + category_name + "/"
                if not os.path.exists(image_export_path):
                    os.makedirs(image_export_path)
                bake_image.filepath_raw = image_export_path + model_name + ".png"
                bake_image.file_format = 'PNG'
                bake_image.save()
            
            #Remove the old uvmap and make sure the new uvmap is the main one.
            obj.data.uv_layers.remove(obj.data.uv_layers["UVMap"])
            
            #Export the obj file.
            if export_model:
                obj_export_path = resolved_export_path + "/Models/kenney/" + category_name + "/"
                if not os.path.exists(obj_export_path):
                    os.makedirs(obj_export_path)
                bpy.ops.export_scene.obj(filepath=obj_export_path + model_name + ".obj", use_materials=False)
            
            #Create the object xml.
            #First the model path.
            model_xml = object_xml_root.createElement('Model')
            model_path = object_xml_root.createTextNode("Data/Models/kenney/" + category_name + "/" + model_name + ".obj")
            model_xml.appendChild(model_path)
            object_xml.appendChild(model_xml)
            
            #Then the colormap.
            colormap_xml = object_xml_root.createElement('ColorMap')
            colormap_path = object_xml_root.createTextNode("Data/Textures/kenney/" + category_name + "/" + model_name + ".png")
            colormap_xml.appendChild(colormap_path)
            object_xml.appendChild(colormap_xml)
            
            #The normalmap is all the same.
            normalmap_xml = object_xml_root.createElement('NormalMap')
            normalmap_path = object_xml_root.createTextNode("Data/Textures/normal.tga")
            normalmap_xml.appendChild(normalmap_path)
            object_xml.appendChild(normalmap_xml)
            
            #The shadername is also the same.
            shadername_xml = object_xml_root.createElement('ShaderName')
            if any(plant_name in model_name for plant_name in plant_names):
                shadername_path = object_xml_root.createTextNode("plant")
                
                #Add an extra tag for doublesided.
                flags_xml = object_xml_root.createElement('flags')
                flags_xml.setAttribute('no_collision', 'true')
                #Plants are double sided by default.
                flags_xml.setAttribute('double_sided', 'true')
                object_xml.appendChild(flags_xml)
            else:
                shadername_path = object_xml_root.createTextNode("envobject #TANGENT")
                #An extra check to see if this object is double sided.
                if any(double_sided_name in model_name for double_sided_name in double_sided_names):
                    flags_xml = object_xml_root.createElement('flags')
                    flags_xml.setAttribute('no_collision', 'true')
                    flags_xml.setAttribute('double_sided', 'true')
                    object_xml.appendChild(flags_xml)
                
            shadername_xml.appendChild(shadername_path)
            object_xml.appendChild(shadername_xml)
              
            xml_str = object_xml_root.toprettyxml(indent ="\t")
            print(xml_str)
            
            #Export the XML.
            if export_xml:
                xml_export_path = resolved_export_path + "/Objects/kenney/" + category_name + "/"
                if not os.path.exists(xml_export_path):
                    os.makedirs(xml_export_path)
                
                with open(xml_export_path + model_name + ".xml", "w", encoding="utf8") as outfile:
                    outfile.write(xml_str)
            
            #Copy the thumbnails from the import folder to the export folder.
            if export_thumbnails:
                from_thumbnail_path = resolved_thumbnail_path + "/" + model_name
                to_thumbnail_path = resolved_export_path + "/UI/spawner/thumbs/kenney/" + category_name + "/"
                if not os.path.exists(to_thumbnail_path):
                    os.makedirs(to_thumbnail_path)
                copyfile(from_thumbnail_path + "_NE.png", to_thumbnail_path + "/" + model_name + "_NE.png")
                copyfile(from_thumbnail_path + "_NW.png", to_thumbnail_path + "/" + model_name + "_NW.png")
                copyfile(from_thumbnail_path + "_SE.png", to_thumbnail_path + "/" + model_name + "_SE.png")
                copyfile(from_thumbnail_path + "_SW.png", to_thumbnail_path + "/" + model_name + "_SW.png")
            
            #Create the xml to be inserted into the mod.xml.
            item = root.createElement('Item')
            item.setAttribute('category', 'Kenney ' + category_name.replace("_", " "))
            item_title = model_name.replace("_", " ")
            item.setAttribute('title', item_title.title())
            item.setAttribute('path', "Data/Objects/kenney/" + category_name + "/" + model_name + ".xml")
            item.setAttribute('thumbnail', "Data/UI/spawner/thumbs/kenney/" + category_name + "/" + model_name + "_NE.png")
              
            xml.appendChild(item)
            clear()
#            break
        
    xml_str = root.toprettyxml(indent ="\t")
    print(xml_str)
    
    with open(resolved_export_path + "/new_assets.xml", "w", encoding="utf8") as outfile:
        outfile.write(xml_str)

def clear():
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

class ImportOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.import"
    
    def execute(self, context):
        clear()
        global export_model
        global export_xml
        global export_thumbnails
        global export_texture
        
        export_model = context.scene.export_model
        export_xml = context.scene.export_xml
        export_thumbnails = context.scene.export_thumbnails
        export_texture = context.scene.export_texture
        
        get_models(context.scene.import_path, context.scene.export_path, self)
        return {'FINISHED'}

class ClearOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.clear"
    
    def execute(self, context):
        clear()
        return {'FINISHED'}

class OGLevelImport(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Overgrowth Level Import"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        self.layout.prop(context.scene, "import_path")
        self.layout.prop(context.scene, "export_path")
        self.layout.prop(context.scene, "export_xml")
        self.layout.prop(context.scene, "export_thumbnails")
        self.layout.prop(context.scene, "export_model")
        self.layout.prop(context.scene, "export_texture")
        
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