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
from functools import partial
from os import path
from PIL import Image, ImageDraw, ImageFilter
from sys import argv
import json
import os
import re
import struct

bpy.types.Scene.export_path = StringProperty(subtype='DIR_PATH', name="Export Path")
bpy.types.Scene.model_name = StringProperty(subtype='FILE_NAME', name="Model Name")
bpy.types.Scene.cache_path = StringProperty(subtype='FILE_PATH', name="Cache Path")

# This is the max the vertex can move out of it's own rest pose. 5 units each way.
bounds = Vector([20.0, 20.0, 20.0])

SUPPORTED_CACHE_FILE_VERSION = 41

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

def BoundedVec3ToTexture(value, x, y, output_image, image_size, animation_length):
    # Range need to be adjusted so it's between 0.0 - 1.0f;
    origin_adjusted_location = value + (bounds / 2.0)
    range_adjusted_location = origin_adjusted_location / bounds.x
    
    # The y and z axis need to be swapped so they are correct in-engine.
    swapped = Vector([range_adjusted_location.x, range_adjusted_location.z, range_adjusted_location.y * -1.0])
    
    Vec3ToTexture(swapped, x, y, output_image, image_size, animation_length)

def Vec3ToTexture(value, x, y, output_image, image_size, animation_length):
    split_x = EncodeFloatRG(value.x)
    split_y = EncodeFloatRG(value.y)
    split_z = EncodeFloatRG(value.z)
    
    color_image_1 = (split_x.x, split_y.x, split_z.x, 1.0)
    color_image_2 = (split_x.y, split_y.y, split_z.y, 1.0)
    
    SetPixel(output_image, x, y, color_image_1, image_size)
    SetPixel(output_image, x, y - animation_length, color_image_2, image_size)

def CreateAnimationTextures(export_path, model_name, info):
    # The image size can be increased to hold more animations, vertices or longer animation.
    image_size = 1
    arm = None
    selected_objects = []
    copied_objects = []
    
    for object in bpy.context.selected_objects:
        if object.type == 'MESH':
            obj_copy = object.copy()
            obj_copy.data = obj_copy.data.copy()
            bpy.context.collection.objects.link(obj_copy)
            copied_objects.append(obj_copy)
            selected_objects.append(object)
        elif object.type == 'ARMATURE':
            arm = object
        
        object.select_set(False)
    
    if not arm is None:
        arm.data.pose_position = 'REST'
    
    joined_object = copied_objects[0]
    ctx = bpy.context.copy()
    ctx['active_object'] = joined_object
    ctx['selected_editable_objects'] = copied_objects
    bpy.ops.object.join(ctx)
    
    bpy.context.view_layer.update()
    
    joined_object.select_set(True)
#    joined_object.parent = None
#    joined_object.modifiers.clear()

    if joined_object.data.shape_keys != None and len(joined_object.data.shape_keys.key_blocks.keys()) > 0:
        joined_object.active_shape_key_index = 0
    
    bpy.context.view_layer.objects.active = joined_object
    
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    target_folder = str(Path(directory + export_path).resolve())
    
    bpy.context.view_layer.update()
    
    obj_file = target_folder + "/Models/" + model_name + ".obj"
    bpy.ops.export_scene.obj(filepath=obj_file, check_existing=True, axis_forward='-Z', axis_up='Y', filter_glob="*.obj;*.mtl", use_selection=True, use_animation=False, use_mesh_modifiers=True, use_edges=True, use_smooth_groups=False, use_smooth_groups_bitflags=False, use_normals=True, use_uvs=True, use_materials=False, use_triangles=False, use_nurbs=False, use_vertex_groups=False, use_blen_objects=False, group_by_object=False, group_by_material=False, keep_vertex_order=True, global_scale=1, path_mode='AUTO')
    
    center_location = joined_object.location
    
    vertex_count = len(joined_object.data.vertices)
    while(image_size < vertex_count):
        image_size *= 2
    
    if not bpy.context.object.rigid_body is None:
        bpy.ops.rigidbody.objects_remove()
    
    #------------------------------------------------
    
    # Remove any existing images before creating new ones.
    if bpy.data.images.get('Output') != None:
        bpy.data.images.remove(bpy.data.images['Output'])
    
    bpy.ops.image.new(name='Output', width=image_size, height=image_size, alpha=False)
    output_image = bpy.data.images['Output']
    output_image.filepath_raw = target_folder + "/Textures/" + model_name + ".png"
    output_image.file_format = 'PNG'

    # The vertices location in rest position is used to calculate the vertex offset for the animation.
    rest_data = []
    
    pixels = list(output_image.pixels)
    
    depgraph = bpy.context.evaluated_depsgraph_get()
    bme = bmesh.new()
    bme.from_object(joined_object, depgraph)
    bme.verts.ensure_lookup_table()
    
    for v in bme.verts:
        rest_data.append(v.co.copy())
    
    bme.free()
    
    #-------------------------------------------
    
    frame_counter = 0
    
    frame_start = bpy.context.scene.frame_start
    frame_end = bpy.context.scene.frame_end
    
    animation_length = frame_end - frame_start
    print("Animation Length : ", animation_length)

    bpy.context.scene.frame_set(frame_start)
    bpy.context.view_layer.update()
    
    if not arm is None:
        arm.data.pose_position = 'POSE'
    
    # Each animation frame is single pixel in the x axis on the texture.
    for frame_index in range(frame_start, frame_end + 1):
        print("Frame", frame_counter, "/", (frame_end - frame_start))
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
                
                BoundedVec3ToTexture(difference, position_x, position_y, pixels, image_size, animation_length)
                vertex_counter += 1
            
            bm.free()
    
    settings = Vector([(frame_counter - 1) / 10000.0, (frame_counter - 1) / 10000.0, (frame_counter - 1) / 10000.0])
    Vec3ToTexture(settings, 0, image_size - 1, pixels, image_size, 1)
    
    print("Image size :", image_size, "px")
    print("Vertex count :", vertex_count)
    print("Animation length :", frame_counter)
    print("Center Location :", center_location)
    print("Start Pixel :", 3)
    print("End Pixel :", 3 + animation_length)
    print("Calculated length :", (3 + animation_length) - 3)
    
    output_image.pixels[:] = pixels
    # Should probably update image
    output_image.update()
    output_image.save()
    
    bpy.data.objects.remove(joined_object, do_unlink=True)
    
    bpy.context.scene.frame_set(frame_start)

def read_tuple(input_file, bytes_for_field, byte_struct_format_string, field_name):
    field_bytes = input_file.read(bytes_for_field)

    if not field_bytes or len(field_bytes) < bytes_for_field:
        print('file truncated while reading ', field_name, sep='')
        return None

    result = struct.unpack(byte_struct_format_string, field_bytes)  # result is always a tuple, even if byte_struct_format)string only contains a single value

    return result


def read_scalar(input_file, bytes_for_field, byte_struct_format_string, field_name):
    result, = read_tuple(input_file, bytes_for_field, byte_struct_format_string, field_name)  # unpacks tuple with (assumed) single value into scalar
    return result


def read_tuple_array(input_file, output_array, array_count, bytes_per_entry, byte_struct_format_string, field_name):
    for current_array_index in range(array_count):
        current_array_entry_bytes = input_file.read(bytes_per_entry)

        if not current_array_entry_bytes or len(current_array_entry_bytes) < bytes_per_entry:
            print('file truncated while reading ', field_name, '. at index: ', current_array_index, sep='')
            return False

        current_array_entry = struct.unpack(byte_struct_format_string, current_array_entry_bytes)
        output_array.append(current_array_entry)

    return True


def read_scalar_array(input_file, output_array, array_count, bytes_per_entry, byte_struct_format_string, field_name):
    for current_array_index in range(array_count):
        current_array_entry_bytes = input_file.read(bytes_per_entry)

        if not current_array_entry_bytes or len(current_array_entry_bytes) < bytes_per_entry:
            print('file truncated while reading ', field_name, '. at index: ', current_array_index, sep='')
            return False

        current_array_entry, = struct.unpack(byte_struct_format_string, current_array_entry_bytes)
        output_array.append(current_array_entry)

    return True


def read_file(input_file):
    # read initial header and verify version matches parser
    file_checksum, file_version = read_tuple(input_file, 4, '=HH', 'file_checksum and file_version')
    if file_checksum is None:
        return None

    global SUPPORTED_CACHE_FILE_VERSION
    if file_version != SUPPORTED_CACHE_FILE_VERSION:
        print('file is wrong version. expected:', SUPPORTED_CACHE_FILE_VERSION, 'actual:', file_version)
        return None

    # read rest of file
    vertex_count = read_scalar(input_file, 4, '=i', 'vertex_count')
    if vertex_count is None:
        return None

    vertices = []
    if not read_tuple_array(input_file, vertices, vertex_count, 12, '=fff', 'vertices'):
        return None

    normals = []
    if not read_tuple_array(input_file, normals, vertex_count, 12, '=fff', 'normals'):
        return None

    tangents = []
    if not read_tuple_array(input_file, tangents, vertex_count, 12, '=fff', 'tangents'):
        return None

    bitangents = []
    if not read_tuple_array(input_file, bitangents, vertex_count, 12, '=fff', 'bitangents'):
        return None

    tex_coords = []
    if not read_tuple_array(input_file, tex_coords, vertex_count, 8, '=ff', 'tex_coords'):
        return None

    face_count = read_scalar(input_file, 4, '=i', 'face_count')
    if face_count is None:
        return None

    face_vertex_indices = []
    if not read_tuple_array(input_file, face_vertex_indices, face_count, 12, '=III', 'face_vertex_indices'):
        return None

    face_normals = []
    if not read_tuple_array(input_file, face_normals, face_count, 12, '=fff', 'face_normals'):
        return None

    precollapse_num_vertices = read_scalar(input_file, 4, '=i', 'precollapse_num_vertices')
    if precollapse_num_vertices is None:
        return None

    precollapse_vert_reorder_index_count = read_scalar(input_file, 4, '=i', 'precollapse_vert_reorder_index_count')
    if precollapse_vert_reorder_index_count is None:
        return None

    precollapse_vert_reorder_indices = []
    if not read_scalar_array(input_file, precollapse_vert_reorder_indices, precollapse_vert_reorder_index_count, 4, '=i', 'precollapse_vert_reorder_indices'):
        return None

    optimize_vert_reorder_index_count = read_scalar(input_file, 4, '=i', 'optimize_vert_reorder_index_count')
    if optimize_vert_reorder_index_count is None:
        return None

    optimize_vert_reorder_indices = []
    if not read_scalar_array(input_file, optimize_vert_reorder_indices, optimize_vert_reorder_index_count, 4, '=i', 'optimize_vert_reorder_indices'):
        return None

    tex_coord2_count = read_scalar(input_file, 4, '=i', 'tex_coord2_count')
    if tex_coord2_count is None:
        return None

    tex_coords2 = []
    if not read_tuple_array(input_file, tex_coords2, tex_coord2_count, 8, '=ff', 'tex_coords2'):
        return None

    min_coords = read_tuple(input_file, 12, '=fff', 'min_coords')
    if min_coords is None:
        return None

    max_coords = read_tuple(input_file, 12, '=fff', 'max_coords')
    if max_coords is None:
        return None

    center_coords = read_tuple(input_file, 12, '=fff', 'center_coords')
    if center_coords is None:
        return None

    old_center_coords = read_tuple(input_file, 12, '=fff', 'old_center_coords')
    if old_center_coords is None:
        return None

    bounding_sphere_origin = read_tuple(input_file, 12, '=fff', 'bounding_sphere_origin')
    if bounding_sphere_origin is None:
        return None

    bounding_sphere_radius = read_scalar(input_file, 4, '=f', 'bounding_sphere_radius')
    if bounding_sphere_radius is None:
        return None

    texel_density = read_scalar(input_file, 4, '=f', 'texel_density')
    if texel_density is None:
        return None

    average_triangle_edge_length = read_scalar(input_file, 4, '=f', 'average_triangle_edge_length')
    if average_triangle_edge_length is None:
        return None

    # parsed successfully. return result
    return {
        'file_checksum': file_checksum,
        'file_version': file_version,
        'vertex_count': vertex_count,
        'vertices': vertices,
        'normals': normals,
        'tangents': tangents,
        'bitangents': bitangents,
        'tex_coords': tex_coords,
        'face_count': face_count,
        'face_vertex_indices': face_vertex_indices,
        'face_normals': face_normals,
        'precollapse_num_vertices': precollapse_num_vertices,
        'precollapse_vert_reorder_index_count': precollapse_vert_reorder_index_count,
        'precollapse_vert_reorder_indices': precollapse_vert_reorder_indices,
        'optimize_vert_reorder_index_count': optimize_vert_reorder_index_count,
        'optimize_vert_reorder_indices': optimize_vert_reorder_indices,
        'tex_coord2_count': tex_coord2_count,
        'tex_coords2': tex_coords2,
        'min_coords': min_coords,
        'max_coords': max_coords,
        'center_coords': center_coords,
        'old_center_coords': old_center_coords,
        'bounding_sphere_origin': bounding_sphere_origin,
        'bounding_sphere_radius': bounding_sphere_radius,
        'texel_density': texel_density,
        'average_triangle_edge_length': average_triangle_edge_length,
    }


def CreateJSON(cache_path, model_name, info):
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    target_file = str(Path(directory + cache_path).resolve())
    
    if not path.exists(target_file):
        print('file not found:', target_file)
        return
    
    with open(target_file, mode='rb') as file:
        parsed_file = read_file(file)

        if parsed_file:
            with open(directory + '/' + model_name + '.json', 'w') as outfile:
                outfile.write(json.dumps(parsed_file, indent = 4))


def SortTextures(cache_path, export_path, model_name, info):
    blend_file_path = bpy.data.filepath
    directory = os.path.dirname(blend_file_path)
    
    input_model_obj_filename = str(Path(directory + export_path + "/Models/" + model_name + ".obj").resolve())
    input_model_cache_json_filename = str(Path(directory + "/" + model_name + ".json").resolve())
    input_image_filename = str(Path(directory + export_path + "/Textures/" + model_name + ".png").resolve())
    output_image_filename = str(Path(directory + export_path + "/Textures/" + model_name + "_sorted.png").resolve())
    
    print("obj", input_model_obj_filename)
    print("json", input_model_cache_json_filename)
    
    if not path.exists(input_model_obj_filename):
        print('file not found:', input_model_obj_filename)
        return

    if not path.exists(input_model_cache_json_filename):
        print('file not found:', input_model_cache_json_filename)
        return

    if not path.exists(input_image_filename):
        print('file not found:', input_image_filename)
        return

    # load model checksum
    original_model_checksum = 0

    with open(input_model_obj_filename, mode='rb') as input_obj_file_binary:
        input_obj_file_binary.seek(0, os.SEEK_END)
        short_count = int(input_obj_file_binary.tell() / 2)
        input_obj_file_binary.seek(0, os.SEEK_SET)

        for current_short_index in range(short_count):
            chunk = input_obj_file_binary.read(2)
            current_chunk_value, = struct.unpack('=H', chunk)
            original_model_checksum = original_model_checksum + current_chunk_value

        original_model_checksum = original_model_checksum % 65536

    # load model vertices
    original_model_face_vertex_indices = []

    with open(input_model_obj_filename) as input_obj_file:
        for line in input_obj_file:
            match = re.match('^f (\\d+)(?:/\\d+)?(?:/\\d+)? (\\d+)(?:/\\d+)?(?:/\\d+)? (\\d+)(?:/\\d+)?(?:/\\d+)?$', line)
            if match:
                # obj file indices are 1-based not 0-based
                original_model_face_vertex_indices.append(int(match.group(1)) - 1)
                original_model_face_vertex_indices.append(int(match.group(2)) - 1)
                original_model_face_vertex_indices.append(int(match.group(3)) - 1)

    original_model_face_vertex_indices_count = len(original_model_face_vertex_indices)

    # load model cache data
    model_cache_data = None

    with open(input_model_cache_json_filename) as input_json_file:
        model_cache_data = json.load(input_json_file)

        if not model_cache_data:
            print('unable to parse model cache input file:', input_model_cache_json_filename)
            print_usage()
            return

    model_cache_checksum = model_cache_data['file_checksum']
    model_cache_precollapse_vertex_indices_count = model_cache_data['precollapse_num_vertices']

    # verify model and cache match
    if original_model_checksum != model_cache_checksum:
        print('original model file and model cache file had inconsistent checksum.')
        print('original model checksum:', original_model_checksum)
        print('model cache checksum:', model_cache_checksum)
        return

    if original_model_face_vertex_indices_count != model_cache_precollapse_vertex_indices_count:
        print('original model file and model cache file had inconsistent vertex indices count.')
        print('original model face vertex indices count:', original_model_face_vertex_indices_count)
        print('model cache pre-collapse vertex indices count:', model_cache_precollapse_vertex_indices_count)
        return

    # create map of final collapsed and optimized vertex indices to original vertex indices
    precollapse_vert_reorder_indices = model_cache_data["precollapse_vert_reorder_indices"]  # map of post-collapse vertex indices to original model vertex indices
    optimize_vert_reorder_indices = model_cache_data["optimize_vert_reorder_indices"]  # map of optimized vertex order indices to post-collapse vertex indices

    collapsed_indices = [
        original_model_face_vertex_indices[collapsed_index]
        for collapsed_index in precollapse_vert_reorder_indices
    ]
    optimized_indices = [
        collapsed_indices[optimized_index]
        for optimized_index in optimize_vert_reorder_indices
    ]

    with Image.open(input_image_filename) as input_image:
        column_height = input_image.height
        greatest_input_dimension = max(model_cache_data['optimize_vert_reorder_index_count'], column_height)
        output_image_dimensions = 1 << (greatest_input_dimension - 1).bit_length()  # smallest power of 2 that is >= greatest_input_dimension
        
        output_image = Image.new(mode='RGB', size=(output_image_dimensions, output_image_dimensions))
            
        # The settings are on the first row of the image. So copy those over.
        copied_row = input_image.crop((0, 0, column_height, column_height))
        output_image.paste(copied_row, (0, 0, column_height, column_height))

        for output_column_index, input_column_index in enumerate(optimized_indices):
            copied_column = input_image.crop((input_column_index, 2, input_column_index + 1, column_height))
            output_image.paste(copied_column, (output_column_index, 2, output_column_index + 1, column_height))

        output_image.save(output_image_filename)
        print("Written sorted image", output_image_filename)


class VAT_OT_CreateTextures(Operator):
    bl_label = "Operator"
    bl_idname = "object.create_textures"
    
    def execute(self, context):
        print("check")
        CreateAnimationTextures(context.scene.export_path, str(context.scene.model_name), self)
        return {'FINISHED'}


class VAT_OT_CreateJSON(Operator):
    bl_label = "Operator"
    bl_idname = "object.create_json"
    
    def execute(self, context):
        CreateJSON(context.scene.cache_path, str(context.scene.model_name), self)
        return {'FINISHED'}


class VAT_OT_SortTextures(Operator):
    bl_label = "Operator"
    bl_idname = "object.sort_textures"
    
    def execute(self, context):
        SortTextures(context.scene.cache_path, context.scene.export_path, str(context.scene.model_name), self)
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
        row.operator(VAT_OT_CreateTextures.bl_idname, text="Create Textures", icon="LIBRARY_DATA_DIRECT")
        
        self.layout.prop(context.scene, "cache_path")
        row = layout.row()
        row.operator(VAT_OT_CreateJSON.bl_idname, text="Create JSON", icon="LIBRARY_DATA_DIRECT")
        row = layout.row()
        row.operator(VAT_OT_SortTextures.bl_idname, text="Sort Textures", icon="LIBRARY_DATA_DIRECT")


def register():
    bpy.utils.register_class(VAT_OT_CreateTextures)
    bpy.utils.register_class(VAT_OT_CreateJSON)
    bpy.utils.register_class(VAT_OT_SortTextures)
    bpy.utils.register_class(VAT_PT_Panel)


def unregister():
    bpy.utils.unregister_class(VAT_OT_CreateTextures)
    bpy.utils.unregister_class(VAT_OT_CreateJSON)
    bpy.utils.unregister_class(VAT_OT_SortTextures)
    bpy.utils.unregister_class(VAT_PT_Panel)


if __name__ == "__main__":
    register()
else:
    print('Starting Vertex Animation Texture Addon')
    register()