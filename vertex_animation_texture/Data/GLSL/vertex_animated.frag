#version 460 core
#extension GL_ARB_shader_storage_buffer_object : enable
#extension GL_ARB_shader_draw_parameters : enable

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

uniform vec4 color_tint;
uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2; // Diffuse cubemap
uniform sampler2D tex3; // Diffuse cubemap
uniform sampler2DShadow tex4; // Shadows
uniform sampler2D tex5;// TranslucencyMap / WeightMap
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;

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

uniform mat4 shadow_matrix[4];
#define shadow_tex_coords tc1
uniform mat4 projection_view_mat;

in vec3 world_vert;

#pragma bind_out_color
out vec4 out_color;

in vec2 frag_tex_coords;
in vec2 tex_coord;
in vec2 base_tex_coord;
in vec3 orig_vert;
in mat3 tangent_to_world;
in vec3 frag_normal;
flat in int instance_id;
in vec3 vertex_color;
flat in int vertex_id;

uniform float overbright;
const float cloud_speed = 0.1;

void main() {
	vec2 pixelated_coord;
	vec2 texture_size = textureSize(tex0, 0);
	float pixels = texture_size.y;

	pixelated_coord.x = (floor(frag_tex_coords.x * pixels) / pixels + ceil(frag_tex_coords.x * pixels) / pixels) / 2.0f;
	pixelated_coord.y = (floor(frag_tex_coords.y * pixels) / pixels + ceil(frag_tex_coords.y * pixels) / pixels) / 2.0f;

	vec4 colormap = textureLod(tex0, pixelated_coord, 0);
	out_color = colormap;
	// out_color.xyz = vertex_color;
}
