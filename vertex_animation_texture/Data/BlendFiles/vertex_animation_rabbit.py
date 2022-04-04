import bpy
import bmesh
from mathutils import *
import os.path
import re
import xml.etree.ElementTree as ET
from xml.etree.ElementTree import XMLParser
from pathlib import Path
from math import radians
from bpy.props import BoolProperty, IntVectorProperty, StringProperty
from bpy.types import (Panel, Operator)

# The image size can be increased to hold more animations, vertices or longer animation.
image_size = 1024
# This is the max the vertex can move out of it's own rest pose. 1.5 units each way.
bounds = Vector([5.0, 5.0, 5.0])

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

def set_pixel(img,x,y,color):
    width = image_size
    
    offs = (x + int(y*width)) * 4
    if offs + 4 < len(img) + 1:
        for i in range(4):
            img[offs + i] = color[i]

def get_pixel(img,x,y):
    width = img.size[0]
    color=[]
    offs = (x + y*width) * 4
    for i in range(4):
        color.append( img.pixels[offs+i] )
    return color

def float_to_textures(f, x, y, output_image_1, output_image_2):
    # Range need to be adjusted so it's between 0.0 - 1.0f;
    origin_adjusted_location = f + (bounds / 2.0)
    range_adjusted_location = origin_adjusted_location / bounds.x
    
    # The y and z axis might need to be swapped so they are correct in-engine.
    split_x = EncodeFloatRG(range_adjusted_location.x)
    split_y = EncodeFloatRG(range_adjusted_location.y)
    split_z = EncodeFloatRG(range_adjusted_location.z)
    
    color_image_1 = (split_x.x, split_y.x, split_z.x, 1.0)
    color_image_2 = (split_x.y, split_y.y, split_z.y, 1.0)
    
    set_pixel(output_image_1, x, y, color_image_1)
    set_pixel(output_image_2, x, y, color_image_2)

def create_animation_textures(info):
    obj = None
    arm = None
    
    for object in bpy.context.selected_objects:
        # The selected mesh is used to export.
        if object.type == 'MESH':
            obj = object
        elif object.type == 'ARMATURE':
            arm = object
    
#    obj = bpy.context.active_object
    
    # Based on the bounds we need to set a background color that's contains NO vertex offset.
    background_value = (bounds.x / 2.0)
    background_value = background_value / bounds.x
    encoded_background_value = EncodeFloatRG(background_value)
    
#    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    
    # The single float value is split into two texture color values.
    background_color_1 = Vector([encoded_background_value.x, encoded_background_value.x, encoded_background_value.x, 1.0])
    background_color_2 = Vector([encoded_background_value.y, encoded_background_value.y, encoded_background_value.y, 1.0])
    
    # Remove any existing images before creating new ones.
    if bpy.data.images.get('Output1') != None:
        bpy.data.images.remove(bpy.data.images['Output1'])
    
    if bpy.data.images.get('Output2') != None:
        bpy.data.images.remove(bpy.data.images['Output2'])
    
    bpy.ops.image.new(name='Output1', width=image_size, height=image_size, color=background_color_1, alpha=True)
    output_image_1 = bpy.data.images['Output1']
    bpy.ops.image.new(name='Output2', width=image_size, height=image_size, color=background_color_2, alpha=True)
    output_image_2 = bpy.data.images['Output2']
    
#    frame_start = bpy.context.scene.frame_start
#    frame_end = bpy.context.scene.frame_end

    # The vertices location in rest position is used to calculate the vertex offset for the animation.
    rest_data = [vert.co for vert in obj.data.vertices]
    frame_counter = 0
    
    pixels_1 = list(output_image_1.pixels)
    pixels_2 = list(output_image_2.pixels)
    
    for rest_index in range(min(image_size, len(rest_data))):
        rest_vert = rest_data[rest_index]
        # The first column of pixels is the vertex rest position.
        float_to_textures(rest_vert, rest_index, image_size - 1, pixels_1, pixels_2)
    
    target_actions = bpy.data.actions
#    target_actions = [bpy.data.actions.get("Run")]
    
    for action in target_actions:
        arm.animation_data.action = bpy.data.actions.get(action.name)
        frame_start, frame_end = map(int, action.frame_range)
        print(action.name, frame_start, frame_end)
    
        bpy.context.scene.frame_set(frame_start)
        bpy.context.view_layer.update()
        
        # Each animation frame is single pixel in the x axis on the texture.
        for frame_index in range(frame_start, frame_end + 1):
            bpy.context.scene.frame_set(frame_index)
            bpy.context.view_layer.update()
    #        print("Animation frame", frame_index)

            depgraph = bpy.context.evaluated_depsgraph_get()
            bm = bmesh.new()
            bm.verts.ensure_lookup_table()
            bm.from_object(obj, depgraph)
            
            position_y = image_size - 2 - frame_counter
            
            frame_counter += 1
            
            if position_y < 0:
                break

            # Go over all the mesh's vertices in order.
            for v in bm.verts:
                rest_vert = rest_data[v.index]
                vert = v.co
                
                difference = rest_vert - vert
            
                position_x = v.index
                
                float_to_textures(vert, position_x, position_y, pixels_1, pixels_2)
    
    output_image_1.pixels[:] = pixels_1
    output_image_2.pixels[:] = pixels_2

    # Should probably update image
    output_image_1.update()
    output_image_2.update()
    
#    bpy.context.scene.frame_set(frame_start)

class ExecuteOperator(Operator):
    bl_label = "Operator"
    bl_idname = "object.create"
    
    def execute(self, context):
        create_animation_textures(self)
        return {'FINISHED'}

class VertexAnimationTexture(Panel):
    """Creates a Panel in the Object properties window"""
    bl_label = "Vertex Animation Texture"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'TOOLS'

    def draw(self, context):
        layout = self.layout
        row = layout.row()
        row.operator(ExecuteOperator.bl_idname, text="Create", icon="LIBRARY_DATA_DIRECT")

def register():
    bpy.utils.register_class(ExecuteOperator)
    bpy.utils.register_class(VertexAnimationTexture)

def unregister():
    bpy.utils.unregister_class(ExecuteOperator)
    bpy.utils.register_class(VertexAnimationTexture)

if __name__ == "__main__":
    register()
else:
    print('starting addon')
    register()