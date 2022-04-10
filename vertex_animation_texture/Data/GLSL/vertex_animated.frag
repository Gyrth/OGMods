#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

#define detail_normal tex7

uniform vec4 color_tint;
uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2; // Diffuse cubemap
uniform sampler2D tex3; // Diffuse cubemap
uniform sampler2DShadow tex4; // Shadows

UNIFORM_DETAIL4_TEXTURES

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
flat in int skip_render;

uniform float overbright;
const float cloud_speed = 0.1;

UNIFORM_AVG_COLOR4

void main() {
	if(skip_render == 1){
		discard;
	}

	// vec2 pixelated_coord;
	// int normal_image = 0;
	// vec2 texture_size = textureSize(tex0, 0);
	// float pixels = texture_size.y;
	//
	// pixelated_coord.x = (floor(frag_tex_coords.x * pixels) / pixels + ceil(frag_tex_coords.x * pixels) / pixels) / 2.0f;
	// pixelated_coord.y = (floor(frag_tex_coords.y * pixels) / pixels + ceil(frag_tex_coords.y * pixels) / pixels) / 2.0f;

	// vec4 colormap = texture(tex0, pixelated_coord);
	// vec4 colormap = textureLod(detail_normal, vec2(frag_tex_coords), 0.0);
	// vec4 colormap = textureLod(detail_normal, vec3(frag_tex_coords, 1.0), 0.0);
	// vec4 colormap = textureLod(detail_normal, vec3(pixelated_coord, detail_normal_indices[0]), 0.0);

	// vec4 colormap = textureLod(detail_normal, vec3(pixelated_coord, detail_normal_indices[normal_image]), 0.0);
	// vec4 colormap = textureLod(tex0, vec2(frag_tex_coords), 6.0);

	vec4 colormap = texture(tex0, vec2(frag_tex_coords));
	out_color = colormap;

	// out_color.xyz = vertex_color;
}
