#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR

uniform sampler3D tex16;
uniform sampler2D tex17;
uniform sampler2D tex18;
uniform sampler2D tex5;

#if defined(NO_REFLECTION_CAPTURE)
	#define ref_cap_cubemap tex0
#else
	uniform sampler2DArray tex19;

	#define ref_cap_cubemap tex19
#endif

uniform mat4 reflection_capture_matrix[10];
uniform mat4 reflection_capture_matrix_inverse[10];
uniform int reflection_capture_num;

uniform mat4 light_volume_matrix[10];
uniform mat4 light_volume_matrix_inverse[10];
uniform int light_volume_num;
uniform mat4 prev_projection_view_mat;

uniform float haze_mult;

#define INSTANCED_MESH

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

uniform vec4 color_tint;
uniform samplerCube tex3;

#define ref_cap_cubemap tex19

struct Instance {
	mat4 model_mat;
	mat3 model_rotation_mat;
	vec4 color_tint;
	vec4 detail_scale;
};

uniform mat4 shadow_matrix[4];
uniform mat4 projection_view_mat;

in vec3 world_vert;
in vec2 frag_tex_coords;

#pragma bind_out_color
out vec4 out_color;

in vec2 tex_coord;
in vec2 base_tex_coord;
in vec3 orig_vert;
in mat3 tangent_to_world;
in vec3 frag_normal;
flat in int instance_id;
in mat3 tan_to_obj;
const float cloud_speed = 0.1;

uniform float overbright;

#include "decals.glsl"

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords


void ClampCoord(inout vec2 coord, float lod){
	float threshold = 1.0 / (256.0 / pow(2.0, lod+1.0));
	coord[0] = min(coord[0], 1.0 - threshold);
	coord[0] = max(coord[0], threshold);
	coord[1] = min(coord[1], 1.0 - threshold);
	coord[1] = max(coord[1], threshold);
}

vec2 LookupFauxCubemap(vec3 vec, float lod) {
	vec2 coord;

	if(vec.x > abs(vec.y) && vec.x > abs(vec.z)){
		vec3 hit_point = vec3(1.0, vec.y / vec.x, vec.z / vec.x);
		coord = vec2(hit_point.z, hit_point.y) * -0.5 + vec2(0.5);
		ClampCoord(coord, lod);
	}

	if(vec.z > abs(vec.y) && vec.z > abs(vec.x)){
		vec3 hit_point = vec3(1.0, vec.y / vec.z, vec.x / vec.z);
		coord = vec2(hit_point.z*-1.0, hit_point.y) * -0.5 + vec2(0.5);
		ClampCoord(coord, lod);
		coord += vec2(4.0, 0.0);
	}

	if(vec.x < -abs(vec.y) && vec.x < -abs(vec.z)){
		vec3 hit_point = vec3(1.0, vec.y / vec.x, vec.z / vec.x);
		coord = vec2(hit_point.z*-1.0, hit_point.y) * 0.5 + vec2(0.5);
		ClampCoord(coord, lod);
		coord += vec2(1.0, 0.0);
	}

	if(vec.z < -abs(vec.y) && vec.z < -abs(vec.x)){
		vec3 hit_point = vec3(1.0, vec.y / vec.z, vec.x / vec.z);
		coord = vec2(hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
		ClampCoord(coord, lod);
		coord += vec2(5.0, 0.0);
	}

	if(vec.y < -abs(vec.z) && vec.y < -abs(vec.x)){
		vec3 hit_point = vec3(1.0, vec.z / vec.y, vec.x / vec.y);
		coord = vec2(-hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
		ClampCoord(coord, lod);
		coord += vec2(3.0, 0.0);
	}

	if(vec.y > abs(vec.z) && vec.y > abs(vec.x)){
		vec3 hit_point = vec3(1.0, vec.z / vec.y, vec.x / vec.y);
		coord = vec2(hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
		ClampCoord(coord, lod);
		coord += vec2(2.0, 0.0);
	}

	coord.x /= 6.0;
	return coord;
}


vec3 LookupSphereReflectionPos(vec3 world_vert, vec3 spec_map_vec, int which) {
	//vec3 sphere_pos = world_vert - reflection_capture_pos[which];
	//sphere_pos /= reflection_capture_scale[which];
	vec3 sphere_pos = (reflection_capture_matrix_inverse[which] * vec4(world_vert, 1.0)).xyz;

	if(length(sphere_pos) > 1.0){
		return spec_map_vec;
	}

	// Ray trace reflection in sphere
	float test = (2 * dot(sphere_pos, spec_map_vec)) * (2 * dot(sphere_pos, spec_map_vec)) - 4 * (dot(sphere_pos, sphere_pos)-1.0) * dot(spec_map_vec, spec_map_vec);
	test = 0.5 * pow(test, 0.5);
	test = test - dot(spec_map_vec, sphere_pos);
	test = test / dot(spec_map_vec, spec_map_vec);
	return sphere_pos + spec_map_vec * test;
}

vec3 LookUpReflectionShapes(sampler2DArray reflections_tex, vec3 world_vert, vec3 reflect_dir, float lod) {
	#if defined(NO_REFLECTION_CAPTURE)
		return vec3(0.0);
	#else
		vec3 reflection_color = vec3(0.0);
		float total = 0.0;

		for(int i=0; i<reflection_capture_num; ++i){
			//vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
			vec3 temp = (reflection_capture_matrix_inverse[i] * vec4(world_vert, 1.0)).xyz;
			vec3 scale_vec = (reflection_capture_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
			float scale = dot(scale_vec, scale_vec);
			float val = dot(temp, temp);

			if(val < 1.0){
				vec3 lookup = LookupSphereReflectionPos(world_vert, reflect_dir, i);
				vec2 coord = LookupFauxCubemap(lookup, lod);
				float weight = pow((1.0 - val), 8.0);
				weight *= 100000.0;
				weight /= pow(scale, 2.0);
				reflection_color.xyz += textureLod(reflections_tex, vec3(coord, i+1), lod).xyz * weight;
				total += weight;
			}
		}

		if(total < 0.0000001){
			float weight = 0.00000001;
			vec2 coord = LookupFauxCubemap(reflect_dir, lod);
			reflection_color.xyz += textureLod(reflections_tex, vec3(coord, 0), lod).xyz * weight;
			total += weight;
		}

		if(total > 0.0){
			reflection_color.xyz /= total;
		}

		return reflection_color;
	#endif
}

vec3 GetFogColorMult(){
	#if defined(RAINY) || defined(WET)
		#if defined(NO_SKY_HIGHLIGHT)
			return vec3(1.0);
		#else
			return vec3(1.0) + primary_light_color.xyz * pow((dot(normalize(world_vert-cam_pos), ws_light) + 1.0)*0.5, 4.0);
		#endif
	#elif defined(VOLCANO)
		return mix(vec3(1.0), vec3(0.2, 1.6, 3.6), max(0.0, normalize(world_vert-cam_pos).y));
	#elif defined(SWAMP) || (defined(WATERFALL_ARENA) && !defined(CAVE))
		// Rainbow should be from 40.89–42 degrees, with red on the outside
		// Double rainbow should be at angles 50-53, with blue on the outside
		vec3 dir = normalize(world_vert-cam_pos);
		float dot = dot(dir, ws_light);
		float angle = 180 - acos(dot)*180.0/3.1417;
		vec3 rainbow = vec3(0.0);

		if(angle > 39 && angle < 53 && dir.y > 0.0){
			rainbow[0] = max(0.0, 1.0-abs(angle-42));
			rainbow[1] = max(0.0, 1.0-abs(angle-41.5));
			rainbow[2] = max(0.0, 1.0-abs(angle-40.89));

			rainbow[0] += max(0.0, 1.0-abs(angle-50.8)*0.8)*0.25;
			rainbow[1] += max(0.0, 1.0-abs(angle-51.5)*0.8)*0.25;
			rainbow[2] += max(0.0, 1.0-abs(angle-52.2)*0.8)*0.25;

			rainbow *= min(1.0, distance(world_vert, cam_pos) * 0.02);

			#if defined(SWAMP)
				rainbow *= 1.0/(cam_pos.y-kBeachLevel+1.0);
			#endif

			rainbow *=  max(0.0, dir.y) * 1.5;
		}

		#if defined(WATERFALL_ARENA)
			rainbow *= 0.5;
		#endif

		vec3 col = vec3(mix(dot + 2.0, 1.0, 0.5)) + rainbow;

		#if defined(WATERFALL_ARENA) && !defined(CAVE)
			col *= 0.15;
		#endif

		return col;
	#elif defined(WATER_HORIZON)
		return vec3(dot(normalize(world_vert-cam_pos), ws_light) + 2.0)*0.5;
	#elif defined(SWAMP)
		return vec3(dot(normalize(world_vert-cam_pos), ws_light) + 2.0);
	#elif defined(SNOW_EVERYWHERE2)
		vec3 normal = normalize(world_vert-cam_pos);
		float gradient = pow(0.5+dot(normal, ws_light)*0.5,3.0);
		vec3 color = mix(vec3(0.1,0.2,0.5), vec3(2.0,1.5,0.7)*1.3, gradient) * 0.25;
		float opac = min(1.0, max(0.0, 1.0 - normal.y));
		color = mix(vec3(0.1,0.1,0.4), color, opac);
		return color;
	#else
		return vec3(1.0);
	#endif
}

float LinearizeDepth(float z) {
    float n = 0.1; // camera z near
    float epsilon = 0.000001;
    float z_scaled = z * 2.0 - 1.0; // Scale from 0 - 1 to -1 - 1
    float B = (epsilon-2.0)*n;
    float A = (epsilon - 1.0);
    float result = B / (z_scaled + A);

    if(result < 0.0){
        result = 99999999.0;
    }

    return result;
}

vec3 blendNormal(vec3 normal){
	vec3 blending = abs(normal);
	blending = normalize(max(blending, 0.00001));
	blending /= vec3(blending.x + blending.y + blending.z);
	return blending;
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

float CloudShadow(vec3 pos){
	#if defined(TEST_CLOUDS_2) && !defined(DEPTH_ONLY) && !defined(CLOUDS_DO_NOT_CAST_SHADOWS)
		return max(0.0, fractal(pos.zx*0.05+vec2(0.0,time*cloud_speed))*2.0+1.0);
	#else
		return 1.0;
	#endif
}

vec4 GetPixelColorMap(vec4 tint){
	vec2 pixelated_coord;
	vec2 texture_size = textureSize(tex0, 0);
	float pixels = texture_size.y;
	vec2 base_tex_coords = frag_tex_coords;

	pixelated_coord.x = (floor(base_tex_coords.x * pixels) / pixels + ceil(base_tex_coords.x * pixels) / pixels) / 2.0f;
	pixelated_coord.y = (floor(base_tex_coords.y * pixels) / pixels + ceil(base_tex_coords.y * pixels) / pixels) / 2.0f;

	float frames = texture_size.x / pixels;
	float max_frames = frames;
	float half_pixel = 0.5f / texture_size.x;

	// Remove any empty sprites.
	for(int i = int(frames); i > 0; i--){
		vec2 test_coord = vec2((1.0f / frames) * (i - 0.5), 0.5f);
		vec4 test_color = textureLod(tex0, test_coord, 0);

		if(test_color.a < 0.1){
			max_frames -= 1;
		}else{
			break;
		}
	}

	float animation_progress;

	#if defined(TINT_PROGRESS)
		animation_progress = min(0.99f, tint.r);
	#else
		animation_progress = mod(time / 1.0, 1.0);
	#endif

	pixelated_coord.x /= frames;
	pixelated_coord.x += (1.0f / frames) * floor(animation_progress * max_frames);

	vec4 colormap = textureLod(tex0, pixelated_coord, 0.0);

	return colormap;
}

void main() {
	vec3 ws_vertex = world_vert - cam_pos;

	if(frag_tex_coords.x < 0.0){
		discard;
	}

	mat3 model_rotation_mat = instances[instance_id].model_rotation_mat;
	vec4 instance_color_tint = instances[instance_id].color_tint;
    vec3 model_normal = model_rotation_mat * frag_normal;
	vec3 ws_normal = vec3(0.0, 0.5, 0.0);

    vec4 colormap = GetPixelColorMap(instance_color_tint);

	if(colormap.a < 0.1){
		discard;
	}

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

	#if defined(NO_INSTANCE_ID)
		int instance_id = 0;
	#endif

	float spec_amount = colormap.a;
	float preserve_wetness = 1.0;
	float ambient_mult = 1.0;
	float env_ambient_mult = 1.0;

	vec3 flame_final_color = vec3(0.0, 0.0, 0.0);
	float flame_final_contrib = 0.0;

	#if defined(INSTANCED_MESH)
		vec4 old_colormap = colormap;
		float old_spec_amount = spec_amount;
	#endif

	float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));

	vec4 shadow_coords[4];

	#if !defined(DEPTH_ONLY)
		shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
		shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
		shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
		shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
	#endif

	vec3 shadow_tex = vec3(1.0);
	shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
	shadow_tex.r *= CloudShadow(world_vert);

    CALC_DIRECT_DIFFUSE_COLOR

    diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0) * GetAmbientContrib(1.0) * ambient_mult * env_ambient_mult;

    vec4 decal_color = colormap;

	#if !defined(DEPTH_ONLY) && !defined(NO_DECALS)

		{
			CalculateDecals(decal_color, model_normal, spec_amount, roughness, preserve_wetness, ambient_mult, env_ambient_mult, world_vert, time, decal_val, flame_final_color, flame_final_contrib);
		}

        float weight = decal_color.r + decal_color.g + decal_color.b;
        out_color.rgb = decal_color.xyz;

		vec3 spec_color = vec3(1.0);
		vec3 light_contrib = diffuse_color.xyz;
        float metalness = 1.0;

		CalculateLightContrib(light_contrib, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);
        out_color.rgb *= light_contrib;

	#endif

    float shadow = GetCascadeShadow(shadow_sampler, shadow_coords, distance(cam_pos,world_vert));
	out_color.xyz *= mix(0.2,1.0,shadow);
}
