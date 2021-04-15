import bpy
import bmesh
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
from os import listdir
from os.path import isfile, join

bpy.types.Scene.import_path = StringProperty(subtype='DIR_PATH', name="Import Path")
bpy.types.Scene.export_path = StringProperty(subtype='FILE_PATH', name="Export Path")
bpy.types.Scene.mod_name = StringProperty(subtype='FILE_NAME', name="Mod Name")
bpy.types.Scene.export_xml = BoolProperty(name="Export XML")
bpy.types.Scene.export_thumbnails = BoolProperty(name="Export Thumbnails")
bpy.types.Scene.export_model = BoolProperty(name="Export Model")
bpy.types.Scene.export_texture = BoolProperty(name="Export Texture")
bpy.types.Scene.single_object_export = BoolProperty(name="Single Object Export")

load_models = True
export_model = True
export_xml = False
export_thumbnails = False
export_texture = True
single_object_export = True

cached_object_names = []
cached_object_meshes = []

plant_names = []
double_sided_names = []

def get_models(import_path, export_path, mod_name, info):
    
    split_path = import_path.split("/")
    category_name = split_path[len(split_path) - 2].replace(" ", "_")
    resolved_export_path = bpy.path.abspath(export_path)
    resolved_import_path = bpy.path.abspath(import_path)
    resolved_thumbnail_path = bpy.path.abspath(import_path + "Isometric")
    print("--------------------------------------")
    print("Import path : ", resolved_import_path)
    print("Export path : ", resolved_export_path)
    print("Category name : ", category_name)
    print("--------------------------------------")

    root = minidom.Document()
    xml = root.createElement('root')
    root.appendChild(xml)
    
#    obj_file_paths = ["/home/gyrth/Documents/GitHub/OGMods/quaternius/Data/BlendFiles/../../../../../Quaternius/RPG Asset Pack/Blends/Gems.blend"]
    obj_file_paths = []
    
    for dirpath, dnames, fnames in os.walk(resolved_import_path):
        for f in fnames:
            if f.endswith(".blend"):
                obj_path = os.path.join(dirpath, f)
                print(obj_path);
                obj_file_paths.append(obj_path)
    
    random.shuffle(obj_file_paths)
    
    #Import all the obj files.
    for obj_file_path in obj_file_paths:
        model_name = bpy.path.display_name_from_filepath(obj_file_path)
        print("--------------------------------------")
        print("Model name : " + model_name)
#        imported_object = bpy.ops.import_scene.obj(filepath=obj_file_path)
        
        files = []
        with bpy.data.libraries.load(obj_file_path) as (data_from, data_to):
            for name in data_from.objects:
                files.append({'name': name})

        bpy.ops.wm.append(directory=obj_file_path+"/Object/", files=files)
        
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
            if obj.type != 'MESH':
                continue
            for material in obj.data.materials:
                did_not_use_nodes = not material.use_nodes
                orig_color = material.diffuse_color
                material.use_nodes = True
                
                for node in material.node_tree.nodes:
#                    print(node.type)
                    if node.type == "TEX_IMAGE":
                        node.interpolation = 'Closest'
                    elif node.type=="EMISSION":
                        if not len(node.outputs['Emission'].links) > 0:
                            continue
                        color = node.inputs['Color'].default_value
                        outputnode = node.outputs['Emission'].links[0].to_node
                        newnode = material.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
                        newnode.inputs['Color'].default_value = color
                        material.node_tree.links.new(newnode.outputs[0], outputnode.inputs[0])
                    elif node.type=="BSDF_GLOSSY":
                        if not len(node.outputs['BSDF'].links) > 0:
                            continue
                        color = node.inputs['Color'].default_value
                        outputnode = node.outputs['BSDF'].links[0].to_node
                        newnode = material.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
                        newnode.inputs['Color'].default_value = color
                        material.node_tree.links.new(newnode.outputs[0], outputnode.inputs[0])
                    elif node.type=="BSDF_GLASS":
                        if not len(node.outputs['BSDF'].links) > 0:
                            continue
#                        inputnode = node.inputs['Color'].links[0].from_nodes
                        color = node.inputs['Color'].default_value
                        outputnode = node.outputs['BSDF'].links[0].to_node
#                        material.node_tree.nodes.remove(node)
                        newnode = material.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
                        newnode.inputs['Color'].default_value = color
                        material.node_tree.links.new(newnode.outputs[0], outputnode.inputs[0])
                    elif node.type=="BSDF_PRINCIPLED":
                        if did_not_use_nodes:
                            node.inputs['Base Color'].default_value = orig_color
                    elif node.type=="BSDF_DIFFUSE":
                        if did_not_use_nodes:
                            node.inputs['Color'].default_value = orig_color
                
                bake_texture = material.node_tree.nodes.new('ShaderNodeTexImage')
                bake_texture.image = bake_image
                bake_texture.interpolation = 'Closest'
                
                nodes = material.node_tree.nodes
                nodes.active = bake_texture
            
        obj = None
        for mesh in obj_objects:
            if mesh.type == 'MESH':
                obj = mesh
                mesh.select_set(True)
                mesh.hide_render=False
            else:
                mesh.select_set(False)
                bpy.data.objects.remove(mesh, do_unlink=True)
        bpy.context.view_layer.objects.active = obj
        
        #Create a thumbnail.
        #Create a texture to render to.
        bpy.ops.image.new(name="thumbnail", width=1024, height=1024, color=(0.0, 0.0, 0.0, 0.0), alpha=True, generated_type='BLANK', float=False, use_stereo_3d=False)
        thumbnail_image = bpy.data.images['thumbnail']
        if export_thumbnails:
            thumbnail_path = resolved_export_path + "/UI/spawner/thumbs/" + mod_name + "/" + category_name + "/"
            if not os.path.exists(thumbnail_path):
                os.makedirs(thumbnail_path)
            
            bpy.ops.view3d.camera_to_view_selected()
            bpy.context.scene.render.filepath = thumbnail_path + "/" + model_name + ".png"
            bpy.ops.render.render(write_still = True)
        
        bpy.ops.object.join()
        
        baked_uv = obj.data.uv_layers.new(name='BakedUV')
        obj.data.uv_layers.active = baked_uv
        
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        
        #Create a new smart uv map for the new texture.
        bpy.ops.mesh.remove_doubles(threshold=0.0001)
        bpy.ops.mesh.normals_make_consistent(inside=False)
        #The angle limit is done in radians not degrees.
        bpy.ops.uv.smart_project(angle_limit = 1.1519, island_margin = 0.01)
        
        bpy.ops.object.mode_set(mode='OBJECT')
        #Now bake the colors and textures from all the materials into one.
        bpy.ops.object.bake(type='DIFFUSE', save_mode='INTERNAL')
        
        triangulate_object(bpy.context.active_object)
        
        #Export the newly created image.
        if export_texture:
            image_export_path = resolved_export_path + "/Textures/" + mod_name + "/" + category_name + "/"
            if not os.path.exists(image_export_path):
                os.makedirs(image_export_path)
            bake_image.filepath_raw = image_export_path + model_name + ".png"
            bake_image.file_format = 'PNG'
            bake_image.save()
        
        #Remove the old uvmap and make sure the new uvmap is the main one.
        orig_uv = None
        for layer in obj.data.uv_layers:
            if layer.name == "UVMap":
                orig_uv = layer
                break

        if not orig_uv is None and not single_object_export:
            obj.data.uv_layers.remove(orig_uv)
        
        #Export the obj file.
        if export_model:
            obj_export_path = resolved_export_path + "/Models/" + mod_name + "/" + category_name + "/"
            if not os.path.exists(obj_export_path):
                os.makedirs(obj_export_path)
            bpy.ops.export_scene.obj(filepath=obj_export_path + model_name + ".obj", use_materials=False)
        
        #Create the object xml.
        #First the model path.
        model_xml = object_xml_root.createElement('Model')
        model_path = object_xml_root.createTextNode("Data/Models/" + mod_name + "/" + category_name + "/" + model_name + ".obj")
        model_xml.appendChild(model_path)
        object_xml.appendChild(model_xml)
        
        #Then the colormap.
        colormap_xml = object_xml_root.createElement('ColorMap')
        colormap_path = object_xml_root.createTextNode("Data/Textures/" + mod_name + "/" + category_name + "/" + model_name + ".png")
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
            #Plants are double sided by default.
            flags_xml.setAttribute('double_sided', 'true')
            object_xml.appendChild(flags_xml)
        else:
            shadername_path = object_xml_root.createTextNode("envobject #TANGENT")
            #An extra check to see if this object is double sided.
            if any(double_sided_name in model_name for double_sided_name in double_sided_names):
                flags_xml = object_xml_root.createElement('flags')
                flags_xml.setAttribute('double_sided', 'true')
                object_xml.appendChild(flags_xml)
            
        shadername_xml.appendChild(shadername_path)
        object_xml.appendChild(shadername_xml)
          
        xml_str = object_xml_root.toprettyxml(indent ="\t")
        print(xml_str)
        
        #Export the XML.
        if export_xml:
            xml_export_path = resolved_export_path + "/Objects/" + mod_name + "/" + category_name + "/"
            if not os.path.exists(xml_export_path):
                os.makedirs(xml_export_path)
            
            with open(xml_export_path + model_name + ".xml", "w", encoding="utf8") as outfile:
                outfile.write(xml_str)
                
        #Create the xml to be inserted into the mod.xml.
        item = root.createElement('Item')
        item.setAttribute('category', mod_name.title() + " " + category_name.replace("_", " "))
        item_title = model_name.replace("_", " ")
        item.setAttribute('title', item_title.title())
        item.setAttribute('path', "Data/Objects/" + mod_name + "/" + category_name + "/" + model_name + ".xml")
        item.setAttribute('thumbnail', "Data/UI/spawner/thumbs/" + mod_name + "/" + category_name + "/" + model_name + ".png")
          
        xml.appendChild(item)
        if single_object_export:
            break
        else:
            clear()
        
    #Write the new spawner items to an xml. This can then be copy pasted to the mod.xml.
    xml_str = root.toprettyxml(indent ="\t")
    with open(resolved_export_path + "/" + mod_name + "_new_assets.xml", "w", encoding="utf8") as outfile:
        outfile.write(xml_str)
    
    print("--------------------------------------")
    print("Done exporting!")

def triangulate_object(obj):
    me = obj.data
    # Get a BMesh representation
    bm = bmesh.new()
    bm.from_mesh(me)

    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    # V2.79 : bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method=0, ngon_method=0)

    # Finish up, write the bmesh back to the mesh
    bm.to_mesh(me)
    bm.free()

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
        global single_object_export
        
        export_model = context.scene.export_model
        export_xml = context.scene.export_xml
        export_thumbnails = context.scene.export_thumbnails
        export_texture = context.scene.export_texture
        single_object_export = context.scene.single_object_export
        
        get_models(context.scene.import_path, context.scene.export_path, context.scene.mod_name, self)
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
        self.layout.prop(context.scene, "mod_name")
        self.layout.prop(context.scene, "export_xml")
        self.layout.prop(context.scene, "export_thumbnails")
        self.layout.prop(context.scene, "export_model")
        self.layout.prop(context.scene, "export_texture")
        self.layout.prop(context.scene, "single_object_export")
        
        row = layout.row()
        row.operator(ImportOperator.bl_idname, text="Export", icon="LIBRARY_DATA_DIRECT")
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