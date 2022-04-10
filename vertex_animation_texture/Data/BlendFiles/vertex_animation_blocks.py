import bpy
import bmesh
import math
from mathutils import *
import os.path
import re
import xml.etree.ElementTree as ET
from xml.etree.ElementTree import XMLParser
from pathlib import Path
from math import radians
from bpy.props import BoolProperty, IntVectorProperty, StringProperty
from bpy.types import (Panel, Operator)

bpy.types.Scene.export_path = StringProperty(subtype='DIR_PATH', name="Export Path")
bpy.types.Scene.model_name = StringProperty(subtype='FILE_NAME', name="Model Name")

# This is the max the vertex can move out of it's own rest pose. 5 units each way.
bounds = Vector([10.0, 10.0, 10.0])

def EncodeFloatRG(v):
    kEncodeMul = Vector([1.0, 255.0])
    kEncodeBit = 1.0 / 255.0
    enc = kEncodeMul * v
    
    enc.x = enc.x % 1
    enc.y = enc.y % 1
    
    enc.x -= enc.y * kEncodeBit
    
    return enc

def DecodeFloatRG(enc):
    kDecodeDot = Vector([1.0, 1 / 255.0])
    return enc.dot(kDecodeDot)

def SetPixel(img, x, y, color, image_size):
    offs = (x + int(y * image_size)) * 4
    if x >= 0 and x < image_size and y >= 0 and y < image_size:
        for i in range(4):
            img[offs + i] = color[i]

def GetPixel(img,x,y, image_size):
    color = []
    offs = (x + y * image_size) * 4
    for i in range(4):
        color.append( img.pixels[offs + i] )
    return color

def BoundedFloatToTextures(f, x, y, output_image_1, output_image_2, image_size):
    # Range need to be adjusted so it's between 0.0 - 1.0f;
    origin_adjusted_location = f + (bounds / 2.0)
    range_adjusted_location = origin_adjusted_location / bounds.x
    
    FloatToTextures(range_adjusted_location, x, y, output_image_1, output_image_2, image_size)

def FloatToTextures(f, x, y, output_image_1, output_image_2, image_size):
    # The y and z axis might need to be swapped so they are correct in-engine.
    split_x = EncodeFloatRG(f.x)
    split_y = EncodeFloatRG(f.z)
    split_z = EncodeFloatRG(f.y * -1.0)
    
    color_image_1 = (split_x.x, split_y.x, split_z.x, 1.0)
    color_image_2 = (split_x.y, split_y.y, split_z.y, 1.0)
    
    SetPixel(output_image_1, x, y, color_image_1, image_size)
    SetPixel(output_image_2, x, y, color_image_2, image_size)

def CreateAnimationTextures(export_path, model_name, info):
    # The image size can be increased to hold more animations, vertices or longer animation.
    image_size = 1
    selected_objects = []
    copied_objects = []
    
    for object in bpy.context.selected_objects:
        if object.type == 'MESH':
            obj_copy = object.copy()
            obj_copy.data = obj_copy.data.copy()
            bpy.context.collection.objects.link(obj_copy)
            copied_objects.append(obj_copy)
            selected_objects.append(object)
    
    joined_object = copied_objects[0]
    ctx = bpy.context.copy()
    ctx['active_object'] = joined_object
    ctx['selected_editable_objects'] = copied_objects
    bpy.ops.object.join(ctx)
    
    bpy.context.view_layer.update()
    
    for obj in selected_objects:
        obj.select_set(False)
    
    joined_object.select_set(True)
    bpy.context.view_layer.objects.active = joined_object
    
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    target_folder = str(Path(directory + export_path).resolve())
    
    bpy.context.view_layer.update()
    
    obj_file = target_folder + "/Models/" + model_name + ".obj"
    bpy.ops.export_scene.obj(filepath=obj_file, check_existing=True, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl", use_selection=True, use_animation=False, use_mesh_modifiers=True, use_edges=True, use_smooth_groups=False, use_smooth_groups_bitflags=False, use_normals=True, use_uvs=True, use_materials=False, use_triangles=False, use_nurbs=False, use_vertex_groups=False, use_blen_objects=False, group_by_object=False, group_by_material=False, keep_vertex_order=True, global_scale=1, path_mode='AUTO')
    
    center_location = joined_object.location
    print("center_location", center_location)
    
    vertex_count = len(joined_object.data.vertices)
    while(image_size < vertex_count):
        image_size *= 2
    
    bpy.ops.rigidbody.objects_remove()
    
    #------------------------------------------------
    
    # Based on the bounds we need to set a background color that's contains NO vertex offset.
    background_value = (bounds.x / 2.0)
    background_value = background_value / bounds.x
    encoded_background_value = EncodeFloatRG(background_value)
    
    # The single float value is split into two texture color values.
    background_color_1 = Vector([encoded_background_value.x, encoded_background_value.x, encoded_background_value.x, 1.0])
    background_color_2 = Vector([encoded_background_value.y, encoded_background_value.y, encoded_background_value.y, 1.0])
    
    # Remove any existing images before creating new ones.
    if bpy.data.images.get('Output1') != None:
        bpy.data.images.remove(bpy.data.images['Output1'])
    
    if bpy.data.images.get('Output2') != None:
        bpy.data.images.remove(bpy.data.images['Output2'])
    
    bpy.ops.image.new(name='Output1', width=image_size, height=image_size, color=background_color_1, alpha=False)
    output_image_1 = bpy.data.images['Output1']
    output_image_1.filepath_raw = target_folder + "/Textures/" + model_name + "_1.png"
    output_image_1.file_format = 'PNG'
    bpy.ops.image.new(name='Output2', width=image_size, height=image_size, color=background_color_2, alpha=False)
    output_image_2 = bpy.data.images['Output2']
    output_image_2.filepath_raw = target_folder + "/Textures/" + model_name + "_2.png"
    output_image_2.file_format = 'PNG'

    # The vertices location in rest position is used to calculate the vertex offset for the animation.
    rest_data = []
    
    pixels_1 = list(output_image_1.pixels)
    pixels_2 = list(output_image_2.pixels)
    
    depgraph = bpy.context.evaluated_depsgraph_get()
    bme = bmesh.new()
    bme.from_object(joined_object, depgraph)
    bme.verts.ensure_lookup_table()
    
    for v in bme.verts:
        rest_data.append(v.co.copy())
        BoundedFloatToTextures(v.co, v.index, image_size - 2, pixels_1, pixels_2, image_size)
    
    bme.free()
    
    #-------------------------------------------
    
    frame_counter = 0
    
    frame_start = bpy.context.scene.frame_start
    frame_end = bpy.context.scene.frame_end
#    frame_end = frame_start + 1

    bpy.context.scene.frame_set(frame_start)
    bpy.context.view_layer.update()
    
    # Each animation frame is single pixel in the x axis on the texture.
    for frame_index in range(frame_start, frame_end + 1):
        bpy.context.scene.frame_set(frame_index)
        bpy.context.view_layer.update()
        
        depgraph = bpy.context.evaluated_depsgraph_get()
        vertex_counter = 0
        position_y = image_size - 3 - frame_counter
        
        if position_y < 0:
            break
        
        frame_counter += 1

        for obj in selected_objects:
            bm = bmesh.new()
            bm.from_object(obj, depgraph)
            bm.verts.ensure_lookup_table()
            origin_difference = center_location - obj.location
            
            # Go over all the mesh's vertices in order.
            for v in bm.verts:
                rest_vert = rest_data[vertex_counter]
                global_vert = obj.matrix_world @ v.co
                vert = global_vert - center_location
                
                difference = rest_vert - vert
                position_x = vertex_counter
                
                if vertex_counter == 0:
                    print("difference ", difference)
                
                BoundedFloatToTextures(difference, position_x, position_y, pixels_1, pixels_2, image_size)
                vertex_counter += 1
            
            bm.free()
    
    settings = Vector([(frame_counter - 1) / 10000.0, 0.0, 0.0])
    FloatToTextures(settings, 0, image_size - 1, pixels_1, pixels_2, image_size)
    
    output_image_1.pixels[:] = pixels_1
    output_image_2.pixels[:] = pixels_2

    # Should probably update image
    output_image_1.update()
    output_image_2.update()
    
    output_image_1.save()
    output_image_2.save()
    
    bpy.context.scene.frame_set(frame_start)

class VAT_OT_Operator(Operator):
    bl_label = "Operator"
    bl_idname = "object.create"
    
    def execute(self, context):
        CreateAnimationTextures(context.scene.export_path, str(context.scene.model_name), self)
        return {'FINISHED'}

class VAT_PT_Panel(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Vertex Animation Texture"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        self.layout.prop(context.scene, "export_path")
        self.layout.prop(context.scene, "model_name")
        
        row = layout.row()
        row.operator(VAT_OT_Operator.bl_idname, text="Create", icon="LIBRARY_DATA_DIRECT")

def register():
    bpy.utils.register_class(VAT_OT_Operator)
    bpy.utils.register_class(VAT_PT_Panel)

def unregister():
    bpy.utils.unregister_class(ExecuteOperator)
    bpy.utils.register_class(VertexAnimationTexture)

if __name__ == "__main__":
    register()
else:
    print('Starting Vertex Animation Texture Addon')
    register()