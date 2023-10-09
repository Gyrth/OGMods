#version 450 core

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

#if defined(ATTRIB_ENVOBJ_INSTANCING)
	flat in vec3 model_scale_frag;
	flat in vec4 model_rotation_quat_frag;
	flat in vec4 color_tint_frag;

	#if defined(DETAILMAP4)
		flat in vec4 detail_scale_frag;
	#endif
#endif

vec3 GetInstancedModelScale(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return model_scale_frag;
	#else
		return instances[instance_id].model_scale;
	#endif
}

vec4 GetInstancedModelRotationQuat(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return model_rotation_quat_frag;
	#else
		return instances[instance_id].model_rotation_quat;
	#endif
}

vec4 GetInstancedColorTint(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return color_tint_frag;
	#else
		return instances[instance_id].color_tint;
	#endif
}

#if defined(DETAILMAP4)
	vec4 GetInstancedDetailScale(int instance_id) {
		#if defined(ATTRIB_ENVOBJ_INSTANCING)
			return detail_scale_frag;
		#else
			return instances[instance_id].detail_scale;
		#endif
	}
#endif

#if defined(TANGENT)
	#if defined(USE_GEOM_SHADER)
		in mat3 tan_to_obj_fs;

		#define tan_to_obj tan_to_obj_fs
	#else
		in mat3 tan_to_obj;
	#endif
#endif

#if defined(USE_GEOM_SHADER)
	in vec2 frag_tex_coords_fs;

	#define frag_tex_coords frag_tex_coords_fs
#else
	in vec2 frag_tex_coords;
#endif

#if !defined(NO_INSTANCE_ID)
	flat in int instance_id;
#endif

uniform mat4 shadow_matrix[4];
#define shadow_tex_coords tc1
uniform mat4 projection_view_mat;

#pragma bind_out_color
out vec4 out_color;

#define tc0 frag_tex_coords
#define tc1 base_tex_coord

in vec2 tex_coord;
in vec2 base_tex_coord;
in vec3 orig_vert;
in mat3 tangent_to_world;
in vec3 frag_normal;
in vec3 vertex_color;
flat in int vertex_id;

uniform float overbright;
const float cloud_speed = 0.1;

#include "decals.glsl"

in vec3 world_vert;

vec3 quat_mul_vec3(vec4 q, vec3 v) {
    // Adapted from https://github.com/g-truc/glm/blob/master/glm/detail/type_quat.inl
    // Also from Fabien Giesen, according to - https://blog.molecular-matters.com/2013/05/24/a-faster-quaternion-vector-multiplication/
    vec3 quat_vector = q.xyz;
    vec3 uv = cross(quat_vector, v);
    vec3 uuv = cross(quat_vector, uv);
    return v + ((uv * q.w) + uuv) * 2;
}

void main() {
	#ifdef NO_INSTANCE_ID
		int instance_id;
		// discard;
	#endif

	vec4 colormap;
	vec3 os_normal = frag_normal;
	vec3 ws_normal = quat_mul_vec3(GetInstancedModelRotationQuat(instance_id), os_normal);

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

	#if !defined(VERTEX_COLOR)
		out_color.xyz = vertex_color;
		colormap = out_color;
	#else
		colormap = texture(tex0, vec2(frag_tex_coords));
		out_color = colormap;
	#endif

	vec4 ndcPos;
	ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
	ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
	ndcPos.w = 1.0;

	vec4 clipPos = ndcPos / gl_FragCoord.w;
	vec4 eyePos = inv_proj_mat * clipPos;

	float zVal = ZCLUSTERFUNC(eyePos.z);
	zVal = max(0u, min(zVal, grid_size.z - 1u));
	uvec3 g = uvec3(uvec2(gl_FragCoord.xy) / cluster_width, zVal);

	// decal/light cluster stuff
	#if !(defined(NO_DECALS) || defined(DEPTH_ONLY))
		uint decal_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z);
		uint decal_val = texelFetch(cluster_buffer, int(decal_cluster_index)).x;
	#endif

	uint light_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z) + 1u;

	#if defined(DEPTH_ONLY)
		uint light_val = 0U;
	#else
		uint light_val = texelFetch(cluster_buffer, int(light_cluster_index)).x;
	#endif

	float spec_amount = colormap.a;
	float ambient_mult = 1.0;

	#if defined(INSTANCED_MESH)
		vec4 old_colormap = colormap;
		float old_spec_amount = spec_amount;
	#endif

	#if defined(KEEP_SPEC)
		float roughness = (1.0 - normalmap.a);
	#else
		float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));
	#endif

	vec3 ws_vertex = world_vert - cam_pos;

	#if !defined(DEPTH_ONLY) && !defined(NO_DECALS)
		
		vec3 spec_color = vec3(0.0);
		vec3 light_contrib = out_color.xyz;
		CalculateLightContrib(light_contrib, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);
		out_color.xyz = light_contrib;

	#endif

	vec4 shadow_coords[4];

	#if !defined(DEPTH_ONLY)
		shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
		shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
		shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
		shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
	#endif

	#ifdef NO_INSTANCE_ID
		// out_color = texture(tex1, vec2(frag_tex_coords));
		// out_color.xyz = vec3(1.0, 0.0, 0.0);
		// out_color.xyz = world_vert;
		// discard;
	#else
		vec3 shadow_tex = vec3(1.0);
		shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));

		CALC_DIRECT_DIFFUSE_COLOR

		float shadow = GetCascadeShadow(shadow_sampler, shadow_coords, distance(cam_pos, world_vert));
		out_color.xyz *= mix(0.2,1.0,shadow);
	#endif
}
