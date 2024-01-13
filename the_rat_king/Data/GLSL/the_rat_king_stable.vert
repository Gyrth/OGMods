#version 150
#extension GL_ARB_shading_language_420pack : enable
#include "lighting150.glsl"

in vec3 model_translation_attrib;  // set per-instance. separate from rest because it's not needed in the fragment shader, so is not slow on low-end GPUs

#if defined(ATTRIB_ENVOBJ_INSTANCING)
	in vec3 model_scale_attrib;
	in vec4 model_rotation_quat_attrib;
	in vec4 color_tint_attrib;
	in vec4 detail_scale_attrib;
#endif

#if !defined(ATTRIB_ENVOBJ_INSTANCING)

	const int kMaxInstances = 100;

	struct Instance {
		mat4 model_mat;
		mat3 model_rotation_mat;
		vec4 color_tint;
		vec4 detail_scale;
	};

	uniform InstanceInfo {
		Instance instances[kMaxInstances];
	};
#endif

vec4 GetInstancedColorTint(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return color_tint_attrib;
	#else
		return instances[instance_id].color_tint;
	#endif
}

out vec2 frag_tex_coords;
out vec2 tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec3 world_vert;
out mat3 tan_to_obj;

flat out int instance_id;

out vec4 vertex_color;
out vec3 frag_normal;

uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform float time;

in vec3 tangent_attrib;
in vec3 bitangent_attrib;
in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
in vec3 normal_attrib;
in vec3 plant_stability_attrib;

uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;

#define weight_tex tex5
#define detail_color tex6
#define detail_normal tex7

uniform sampler2D weight_tex;
uniform sampler2DArray detail_color;
uniform vec4 detail_color_indices;
uniform sampler2DArray detail_normal;
uniform vec4 detail_normal_indices;

const vec3 bounds = vec3(2.0, 2.0, 2.0);

float DecodeFloatRG(vec2 enc){
	vec2 kDecodeDot = vec2(1.0, 1.0 / 256.0);
	return dot(enc, kDecodeDot);
}

// Converts a color from linear light gamma to sRGB gamma
vec4 fromLinear(vec4 linearRGB)
{
    bvec4 cutoff = lessThan(linearRGB, vec4(0.0031308));
    vec4 higher = vec4(1.055)*pow(linearRGB, vec4(1.0/2.4)) - vec4(0.055);
    vec4 lower = linearRGB * vec4(12.92);

    return mix(higher, lower, cutoff);
}

void main() {
	instance_id = gl_InstanceID;
	int index = gl_VertexID;

	frag_tex_coords = tex_coord_attrib;
	frag_tex_coords[1] = 1.0 - frag_tex_coords[1];

	tan_to_obj = mat3(tangent_attrib, bitangent_attrib, normal_attrib);

	vertex_color = texture(tex5, frag_tex_coords);
	vec4 normal_color = texture(tex1, frag_tex_coords);

	vec2 texture_size = textureSize(tex0, 0);
	float target_resolution = int(texture_size.y);
	float one_pixel_offset = (1.0 / target_resolution);
	float half_pixel_offset = (1.0 / target_resolution) / 2.0;

	int x_pixel = index;
	float x_pos = 1.0 / target_resolution * x_pixel;
	float animation_length = 48.0;

	vec4 tint = GetInstancedColorTint(instance_id);
	float y_pos = tint.g * 1000.0 * one_pixel_offset;

	// Use half a pixel to get the center of the pixel.
	vec4 color_1 = texture(tex0, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset));
	vec4 color_2 = texture(tex0, vec2(x_pos + half_pixel_offset, 0.5 + y_pos + half_pixel_offset));

	color_1 = fromLinear(color_1);
	color_2 = fromLinear(color_2);

	vec3 vertex_position;
	vertex_position.x = DecodeFloatRG(vec2(color_1.x, color_2.x));
	vertex_position.y = DecodeFloatRG(vec2(color_1.y, color_2.y));
	vertex_position.z = DecodeFloatRG(vec2(color_1.z, color_2.z));

	vertex_position = vertex_position * bounds.x;
	vertex_position = vertex_position - (bounds / 2.0f);

	vec3 animated_vertex_position = vertex_attrib - vertex_position;
	vec3 transformed_vertex = (instances[gl_InstanceID].model_mat * vec4(animated_vertex_position, 1.0)).xyz;

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
	world_vert = transformed_vertex;
}