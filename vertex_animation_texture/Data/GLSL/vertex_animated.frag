#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR

#define detail_normal tex7

uniform sampler2D tex3; // Diffuse cubemap

UNIFORM_DETAIL4_TEXTURES

#define INSTANCED_MESH

#if !defined(ATTRIB_ENVOBJ_INSTANCING)
	#if defined(UBO_BATCH_SIZE_8X)
		const int kMaxInstances = 256 * 8;
	#elif defined(UBO_BATCH_SIZE_4X)
		const int kMaxInstances = 256 * 4;
	#elif defined(UBO_BATCH_SIZE_2X)
		const int kMaxInstances = 256 * 2;
	#else
		const int kMaxInstances = 256 * 1;
	#endif

	struct Instance {
		vec3 model_scale;
		vec4 model_rotation_quat;
		vec4 color_tint;
		vec4 detail_scale;  // TODO: DETAILMAP4 only?
	};

	uniform InstanceInfo {
		Instance instances[kMaxInstances];
	};
#endif

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

#include "decals.glsl"

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

	#if defined(VERTEX_COLOR)
		out_color.xyz = vertex_color;
	#else
		vec4 colormap = texture(tex0, vec2(frag_tex_coords));
		out_color = colormap;
	#endif
}
