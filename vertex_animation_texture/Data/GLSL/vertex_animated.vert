#version 150 core
#extension GL_ARB_shader_storage_buffer_object : enable
#extension GL_ARB_shader_draw_parameters : enable
#include "lighting150.glsl"

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

uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform float time;
uniform mat4 mvp;

out vec2 frag_tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec2 tex_coord;
out vec3 world_vert;
out vec3 frag_normal;
out vec3 vertex_color;
flat out int instance_id;
flat out int vertex_id;

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
in vec3 normal_attrib;
in vec3 plant_stability_attrib;

uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;
in int gl_VertexID;
in int gl_InstanceID;
in int gl_DrawID; // Requires GLSL 4.60 or ARB_shader_draw_parameters
in int gl_BaseVertex; // Requires GLSL 4.60 or ARB_shader_draw_parameters
in int gl_BaseInstance; // Requires GLSL 4.60 or ARB_shader_draw_parameters

float DecodeFloatRG(vec2 enc){
	vec2 kDecodeDot = vec2(1.0, 1 / 255.0);
	return dot(enc, kDecodeDot);
}

void main() {
	frag_tex_coords = tex_coord_attrib;

	tex_coord = tex_coord_attrib;
	tex_coord[1] = 1.0 - tex_coord[1];

	float x_frame_position = (instances[gl_InstanceID].color_tint.r);
	// float x_frame_position = (sin(time));

	float expected_vertex_count = 244.0f;
	float top_white_pixel = 168.0f;
	float texture_height = 256.0f;
	vec4 color_value_1 = texture(tex0, vec2(x_frame_position, (gl_VertexID / expected_vertex_count) * (top_white_pixel / texture_height)));
	// vertex_color = color_value_1.xyz;

	// vertex_color = vec3(0.0f);
	// float reveal = (instances[gl_InstanceID].color_tint.g) * 244.0f;
	// if (gl_VertexID < reveal)
	// {
	// 	vertex_color.r = 1.0;
	// }

	vec4 color_value_2 = texture(tex1, vec2(x_frame_position, (gl_VertexID / expected_vertex_count) * (top_white_pixel / texture_height)));

	float position_x = DecodeFloatRG(vec2(color_value_1.x, color_value_2.x));
	float position_y = DecodeFloatRG(vec2(color_value_1.y, color_value_2.y));
	float position_z = DecodeFloatRG(vec2(color_value_1.z, color_value_2.z));

	vec3 animated_vertex_position = vec3(position_x, position_y, position_z);
	vertex_color = animated_vertex_position;

	vec3 transformed_vertex = (instances[gl_InstanceID].model_mat * vec4(vertex_attrib + animated_vertex_position, 1.0)).xyz;

	world_vert = transformed_vertex;
	frag_normal = normal_attrib;

	orig_vert = vertex_attrib;
	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
	vertex_id = gl_VertexID;
}
