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

# The image size can be increased to hold more animations, vertices or longer animation.
image_size = 1024
# This is the max the vertex can move out of it's own rest pose. 1.5 units each way.
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

def SetPixel(img, x, y, color):
    width = image_size
    
    offs = (x + int(y * width)) * 4
    if x >= 0 and x < image_size and y >= 0 and y < image_size:
#    if offs + 4 < len(img) + 1:
        for i in range(4):
            img[offs + i] = color[i]

def GetPixel(img,x,y):
    width = img.size[0]
    color=[]
    offs = (x + y*width) * 4
    for i in range(4):
        color.append( img.pixels[offs+i] )
    return color

def BoundedFloatToTextures(f, x, y, output_image_1, output_image_2):
    # Range need to be adjusted so it's between 0.0 - 1.0f;
    origin_adjusted_location = f + (bounds / 2.0)
    range_adjusted_location = origin_adjusted_location / bounds.x
    
    FloatToTextures(range_adjusted_location, x, y, output_image_1, output_image_2)

def FloatToTextures(f, x, y, output_image_1, output_image_2):
    # The y and z axis might need to be swapped so they are correct in-engine.
    split_x = EncodeFloatRG(f.x)
    split_y = EncodeFloatRG(f.z)
    split_z = EncodeFloatRG(f.y * -1.0)
    
    color_image_1 = (split_x.x, split_y.x, split_z.x, 1.0)
    color_image_2 = (split_x.y, split_y.y, split_z.y, 1.0)
    
    SetPixel(output_image_1, x, y, color_image_1)
    SetPixel(output_image_2, x, y, color_image_2)

def create_animation_textures2(export_path, model_name, info):
    print(export_path)
    
    obj = None
    
    for object in bpy.context.selected_objects:
        # The selected mesh is used to export.
        if object.type == 'MESH':
            obj = object
    
    new_mesh = bpy.data.meshes.new("new_mesh")
    new_obj = bpy.data.objects.new("NewMesh", new_mesh)
    
    col = bpy.data.collections.get("Collection")
    col.objects.link(new_obj)
    new_obj.location = obj.location

    bm = bmesh.new()
    bm.from_mesh(obj.data)
    
    for v in bm.verts:
        vertex_position = v.co
        padded_index = format(v.index, '06')
        # Remove two numbers and replace them.
        x = math.trunc(vertex_position.x * 100.0) / 100.0
        x_last_two = int(padded_index[0 : 2]) / 10000.001
        x = x - x_last_two if x < 0.0 else x + x_last_two
        y = math.trunc(vertex_position.y * 100.0) / 100.0
        y_last_two = int(padded_index[2 : 4]) / 10000.001
        y = y - y_last_two if y < 0.0 else y + y_last_two
        z = math.trunc(vertex_position.z * 100.0) / 100.0
        z_last_two = int(padded_index[4 : 6]) / 10000.001
        z = z - z_last_two if z < 0.0 else z + z_last_two
        
        print("from", vertex_position, "to", (x, y, z))
        v.co = (x, y, z)
    
    bm.to_mesh(new_obj.data)
    bm.free()  # free and prevent further access
    
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    target_file = str(Path(directory + export_path + "/Data/Models").resolve()) + "/" + model_name + ".obj"

    bpy.ops.export_scene.obj(filepath=target_file, check_existing=True, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl", use_selection=True, use_animation=False, use_mesh_modifiers=True, use_edges=True, use_smooth_groups=False, use_smooth_groups_bitflags=False, use_normals=True, use_uvs=True, use_materials=False, use_triangles=False, use_nurbs=False, use_vertex_groups=False, use_blen_objects=False, group_by_object=False, group_by_material=False, keep_vertex_order=True, global_scale=1, path_mode='AUTO')
    
    file = open(target_file, "r")
    edited_file = ""
    counter = 0;
    
    for line in file:
        if line[0 : 2] == 'vn':
            
            number = counter / 1024.0
            second_number = 1.0 - number
            
            str_number = "{:.4f}".format(number)
            second_str_number = "{:.4f}".format(second_number)
            third_str_number = "0.0000"
            
#            edited_file += "vn " + str_number + " " + second_str_number + " " + third_str_number + "\n"
            edited_file += "vn 0.0000 0.0000 1.0000\n"
            
            counter += 1
        else:
            edited_file += line
    
    file.close()
    
    write_file = open(target_file, "w")
    write_file.write(edited_file)
    write_file.close()
    

def CreateAnimationTextures(export_path, model_name, info):
    obj = None
    arm = None
    
    for object in bpy.context.selected_objects:
        # The selected mesh is used to export.
        if object.type == 'MESH':
            obj = object
        elif object.type == 'ARMATURE':
            arm = object
    
    vertex_count = len(obj.data.vertices)
    image_size = 1
    while(image_size < vertex_count):
        image_size *= 2
    
#    obj = bpy.context.active_object
    arm.select_set(False)
#    bpy.context.active_object = obj

    arm.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    
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
    
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    target_folder = str(Path(directory + export_path).resolve())
    
    bpy.ops.image.new(name='Output1', width=image_size, height=image_size, color=background_color_1, alpha=False)
    output_image_1 = bpy.data.images['Output1']
    output_image_1.filepath_raw = target_folder + "/Textures/" + model_name + "_1.png"
    output_image_1.file_format = 'PNG'
    bpy.ops.image.new(name='Output2', width=image_size, height=image_size, color=background_color_2, alpha=False)
    output_image_2 = bpy.data.images['Output2']
    output_image_2.filepath_raw = target_folder + "/Textures/" + model_name + "_2.png"
    output_image_2.file_format = 'PNG'

    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    obj_file = target_folder + "/Models/" + model_name + ".obj"
    bpy.ops.export_scene.obj(filepath=obj_file, check_existing=True, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl", use_selection=True, use_animation=False, use_mesh_modifiers=True, use_edges=True, use_smooth_groups=False, use_smooth_groups_bitflags=False, use_normals=True, use_uvs=True, use_materials=False, use_triangles=False, use_nurbs=False, use_vertex_groups=False, use_blen_objects=False, group_by_object=False, group_by_material=False, keep_vertex_order=True, global_scale=1, path_mode='AUTO')

    # The vertices location in rest position is used to calculate the vertex offset for the animation.
#    rest_data = [vert.co for vert in obj.data.vertices]
    rest_data = []
    
    pixels_1 = list(output_image_1.pixels)
    pixels_2 = list(output_image_2.pixels)
    
    depgraph = bpy.context.evaluated_depsgraph_get()
    bme = bmesh.new()
    bme.from_object(obj, depgraph)
    bme.verts.ensure_lookup_table()
    
    for v in bme.verts:
        rest_data.append(v.co.copy())
        BoundedFloatToTextures(v.co, v.index, image_size - 2, pixels_1, pixels_2)
    
    bme.free()
    
    arm.data.pose_position = 'POSE'
    bpy.context.view_layer.update()
    
    # All the actions or just the currect one.
#    target_actions = bpy.data.actions
    target_actions = [bpy.data.actions.get(arm.animation_data.action.name)]
    frame_counter = 0
    
    for action in target_actions:
        arm.animation_data.action = bpy.data.actions.get(action.name)
        
        if len(target_actions) == 1:
            frame_start = bpy.context.scene.frame_start
            frame_end = bpy.context.scene.frame_end
        else:
            frame_start, frame_end = map(int, action.frame_range)
    
        bpy.context.scene.frame_set(frame_start)
        bpy.context.view_layer.update()
        
        # Each animation frame is single pixel in the x axis on the texture.
        for frame_index in range(frame_start, frame_end + 1):
            bpy.context.scene.frame_set(frame_index)
            bpy.context.view_layer.update()

            depgraph = bpy.context.evaluated_depsgraph_get()
            bm = bmesh.new()
            bm.from_object(obj, depgraph)
            bm.verts.ensure_lookup_table()
            
            position_y = image_size - 3 - frame_counter
            
            if position_y < 0:
                break
            
            frame_counter += 1

            # Go over all the mesh's vertices in order.
            for v in bm.verts:
                rest_vert = rest_data[v.index]
                vert = v.co
                
                difference = rest_vert - vert
                position_x = v.index
                
                BoundedFloatToTextures(difference, position_x, position_y, pixels_1, pixels_2)
            
            bm.free()
    
    settings = Vector([(frame_counter - 1) / 10000.0, 0.0, 0.0])
    FloatToTextures(settings, 0, image_size - 1, pixels_1, pixels_2)
    
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