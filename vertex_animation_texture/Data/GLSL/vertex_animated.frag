#version 450 core

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR

#define detail_normal tex7
uniform sampler2D base_normal_tex;

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
	#endif
#endif

in mat3 tan_to_obj;

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
in vec4 vertex_color;
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

bool step(vec4 color, float x) {
	if(length(color) / 3.0 <= x){
		return true;
	}else{
		return false;
	}
}

vec3 GetAmbientColor(vec3 world_vert, vec3 ws_normal) {
	vec3 ambient_color = vec3(0.0);

	#if defined(CAN_USE_3D_TEX) && !defined(DETAIL_OBJECT)
		bool use_3d_tex = Query3DTexture(ambient_color, world_vert, ws_normal);
	#else
		bool use_3d_tex = false;
	#endif

	if(!use_3d_tex){
		bool use_amb_cube = false;
		vec3 ambient_cube_color[6];

		for(int i=0; i<6; ++i){
			ambient_cube_color[i] = vec3(0.0);
		}

		#if defined(CAN_USE_LIGHT_PROBES)
			uint guess = 0u;
			int grid_coord[3];
			bool in_grid = true;

			for(int i=0; i<3; ++i){
				if(world_vert[i] > grid_bounds_max[i] || world_vert[i] < grid_bounds_min[i]){
					in_grid = false;
					break;
				}
			}

			if(in_grid){
				grid_coord[0] = int((world_vert[0] - grid_bounds_min[0]) / (grid_bounds_max[0] - grid_bounds_min[0]) * float(subdivisions_x));
				grid_coord[1] = int((world_vert[1] - grid_bounds_min[1]) / (grid_bounds_max[1] - grid_bounds_min[1]) * float(subdivisions_y));
				grid_coord[2] = int((world_vert[2] - grid_bounds_min[2]) / (grid_bounds_max[2] - grid_bounds_min[2]) * float(subdivisions_z));
				int cell_id = ((grid_coord[0] * subdivisions_y) + grid_coord[1])*subdivisions_z + grid_coord[2];
				uvec4 data = texelFetch(ambient_grid_data, cell_id/4);
				guess = data[cell_id%4];
				use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, guess);
			}
		#endif

		if(!use_amb_cube){
			ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
		} else {
			ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
		}
	}

	return ambient_color;
}

void main() {
	#ifdef NO_INSTANCE_ID
		int instance_id;
		return;
	#endif

	vec4 colormap;
	vec4 tint = GetInstancedColorTint(instance_id);
	vec4 normalmap = texture(tex1, tc0);
	vec3 unpacked_normal = UnpackTanNormal(normalmap);
	vec3 ws_normal = normalize(quat_mul_vec3(GetInstancedModelRotationQuat(instance_id), tan_to_obj * unpacked_normal));

	#if defined(VERTEX_COLOR)
		colormap = vertex_color;
	#else
		colormap = texture(tex5, vec2(frag_tex_coords));
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

	colormap *= tint.r + 0.2;

	if(step(texture(tex1, frag_tex_coords), (0.48 + (tint.b / 10.0)) )){
		colormap.rgb = vec3(0.1, 0.0, 0.0);
	}

	float spec_amount = 0.1;
	float ambient_mult = 1.0;
	float env_ambient_mult = 1.0;
	float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));
	roughness = 0.0;
	vec3 ws_vertex = world_vert - cam_pos;

	#if !defined(DEPTH_ONLY) && !defined(NO_DECALS)

		vec3 shadow_tex = vec3(1.0);
		vec4 shadow_coords[4];

		shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
		shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
		shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
		shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);

		#if defined(SIMPLE_SHADOW)
			{
				vec3 X = dFdx(world_vert);
				vec3 Y = dFdy(world_vert);
				vec3 norm = normalize(cross(X, Y));
				float slope_dot = dot(norm, ws_light);
				slope_dot = min(slope_dot, 1);
				shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex), slope_dot);
			}
			shadow_tex.r *= ambient_mult;
		#else
			shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
		#endif

		CALC_DIRECT_DIFFUSE_COLOR

		vec3 ambient_color = GetAmbientColor(world_vert, cam_pos - world_vert);
		diffuse_color += ambient_color * GetAmbientContrib(shadow_tex.g) * ambient_mult * env_ambient_mult;
		diffuse_color *= colormap.xyz;
		
		vec3 spec_color = vec3(1.0);
		CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);

		
		
		out_color.rgb = diffuse_color;

	#endif
}
