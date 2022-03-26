#version 150
#extension GL_ARB_shading_language_420pack : enable

#define FIRE_DECAL_ENABLED

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

uniform sampler2DArray tex19;

#define ref_cap_cubemap tex19

uniform mat4 reflection_capture_matrix[10];
uniform mat4 reflection_capture_matrix_inverse[10];
uniform int reflection_capture_num;

uniform mat4 light_volume_matrix[10];
uniform mat4 light_volume_matrix_inverse[10];
uniform int light_volume_num;
uniform mat4 prev_projection_view_mat;

uniform float haze_mult;

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
uniform mat4 projection_view_mat;

#include "decals.glsl"

in vec3 world_vert;
flat in vec3 model_scale_frag;
flat in vec4 model_rotation_quat_frag;
flat in vec4 color_tint_frag;

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

in vec2 frag_tex_coords;

#if !defined(NO_INSTANCE_ID)
	flat in int instance_id;
#endif

#pragma bind_out_color
out vec4 out_color;

#if !defined(NO_VELOCITY_BUF)
	#pragma bind_out_vel
	out vec4 out_vel;
#endif  // NO_VELOCITY_BUF

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

#if defined(SKY) && defined(YCOCG_SRGB)
	vec3 YCOCGtoRGB(in vec4 YCoCg) {
		float Co = YCoCg.r - 0.5;
		float Cg = YCoCg.g - 0.5;
		float Y  = YCoCg.a;

		float t = Y - Cg * 0.5;
		float g = Cg + t;
		float b = t - Co * 0.5;
		float r = b + Co;

		r = max(0.0,min(1.0,r));
		g = max(0.0,min(1.0,g));
		b = max(0.0,min(1.0,b));

		return vec3(r,g,b);
	}
#endif

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


float UnLinearizeDepth(float result) {
	float n = 0.1; // camera z near
	float epsilon = 0.000001;
	float B = (epsilon-2.0)*n;
	float A = (epsilon - 1.0);
	float z_scaled = B / result - A;
	float z = (z_scaled + 1.0) * 0.5;
	return z;
}

#if !defined(DEPTH_ONLY)
	void CalculateLightContribParticle(inout vec3 diffuse_color, vec3 world_vert, uint light_val) {
		// number of lights in current cluster
		uint light_count = (light_val >> COUNT_BITS) & COUNT_MASK;

		// index into cluster_lights
		uint first_light_index = light_val & INDEX_MASK;

		// light list data is immediately after cluster lookup data
		uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
		first_light_index = first_light_index + uint(light_cluster_data_offset);

		// debug option, uncomment to visualize clusters
		//out_color = vec3(min(light_count, 63u) / 63.0);
		//out_color = vec3(g.z / grid_size.z);

		for (uint i = 0u; i < light_count; i++) {
			uint light_index = texelFetch(cluster_buffer, int(first_light_index + i)).x;

			PointLightData l = FetchPointLight(light_index);

			vec3 to_light = l.pos - world_vert;
			// TODO: inverse square falloff
			// TODO: real light equation
			float dist = length(to_light);
			float falloff = max(0.0, (1.0 / dist / dist) * (1.0 - dist / l.radius));

			falloff = min(0.5, falloff);
			diffuse_color += falloff * l.color * 0.5;
		}
	}
#endif // ^ !defined(DEPTH_ONLY)

#if !defined(DETAIL_OBJECT) && !defined(DEPTH_ONLY) && !defined(SKY) && !defined(GPU_PARTICLE_FIELD)
	vec3 LookupSphereReflectionPos(vec3 world_vert, vec3 spec_map_vec, int which) {
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
#endif

const float water_speed = 0.03;

#if !defined(SKY) && !defined(GPU_PARTICLE_FIELD)
	float GetWaterHeight(vec2 pos, vec3 tint){
		float scale = 0.1 * tint[0];
		float height = 0.0;
		float uv_scale = tint[1];
		float scaled_water_speed = water_speed * uv_scale;

		#if defined(SWAMP)
			scaled_water_speed *= 0.4;
		#endif

		pos *= uv_scale;
		height = texture(tex0, pos  * 0.3 + normalize(vec2(0.0, 1.0))*time*scaled_water_speed).x;
		height += texture(tex0, pos * 0.7 + normalize(vec2(1.0, 0.0))*time*3.0*scaled_water_speed).x;
		height += texture(tex0, pos * 1.1 + normalize(vec2(-1.0, 0.0))*time*5.0*scaled_water_speed).x;
		height += texture(tex0, pos * 0.6 + normalize(vec2(-1.0, 1.0))*time*7.0*scaled_water_speed).x;
		height *= scale;

		return height;
	}
#endif

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

#if !defined(DEPTH_ONLY)
	#if defined(CAN_USE_3D_TEX) && !defined(DETAIL_OBJECT) && !defined(SKY) && !defined(GPU_PARTICLE_FIELD)
		bool Query3DTexture(inout vec3 ambient_color, vec3 pos, vec3 normal) {
			bool use_3d_tex = false;
			vec3 ambient_cube_color[6];

			for(int i=0; i<6; ++i){
				ambient_cube_color[i] = vec3(0.0);
			}

			for(int i=0; i<light_volume_num; ++i){
				//vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
				vec3 temp = (light_volume_matrix_inverse[i] * vec4(pos, 1.0)).xyz;
				vec3 scale_vec = (light_volume_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
				float scale = dot(scale_vec, scale_vec);
				float val = dot(temp, temp);

				if(temp[0] <= 1.0 && temp[0] >= -1.0 &&
						temp[1] <= 1.0 && temp[1] >= -1.0 &&
						temp[2] <= 1.0 && temp[2] >= -1.0) {
					vec3 tex_3d = temp * 0.5 + vec3(0.5);
					vec4 test = texture(tex16, vec3((tex_3d[0] + 0)/ 6.0, tex_3d[1], tex_3d[2]));

					if(test.a >= 1.0){
						for(int j=1; j<6; ++j){
							ambient_cube_color[j] = texture(tex16, vec3((tex_3d[0] + j)/ 6.0, tex_3d[1], tex_3d[2])).xyz;
						}

						ambient_cube_color[0] = test.xyz;
						ambient_color = SampleAmbientCube(ambient_cube_color, normal);
						use_3d_tex = true;
					}

					//out_color.xyz = world_vert * 0.01;
				}
			}

			return use_3d_tex;
		}
	#endif

	#if !defined(SKY) && !defined(GPU_PARTICLE_FIELD)
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
	#endif

	#if !defined(DETAIL_OBJECT) && !defined(DEPTH_ONLY) && !defined(SKY) && !defined(GPU_PARTICLE_FIELD)
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
	#endif
#endif // ^ !defined(DEPTH_ONLY)

// From http://www.thetenthplanet.de/archives/1180
mat3 cotangent_frame( vec3 N, vec3 p, vec2 uv )
{
	// get edge vectors of the pixel triangle
	vec3 dp1 = dFdx( p );
	vec3 dp2 = dFdy( p );
	vec2 duv1 = dFdx( uv );
	vec2 duv2 = dFdy( uv );

	// solve the linear system
	vec3 dp2perp = cross( dp2, N );
	vec3 dp1perp = cross( N, dp1 );
	vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

	// construct a scale-invariant frame
	float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
	return mat3( T * invmax, B * invmax, N );
}

bool sphere_collision(vec3 s, vec3 c, vec3 d, float r, out vec3 intersection, out vec3 normal){
	// Calculate ray start's offset from the sphere center
	vec3 p = s - c;

	float rSquared = r * r;
	float p_d = dot(p, d);

	// The sphere is behind or surrounding the start point.
	if(p_d > 0 || dot(p, p) < rSquared) {
		return false;
	}

	// Flatten p into the plane passing through c perpendicular to the ray.
	// This gives the closest approach of the ray to the center.
	vec3 a = p - p_d * d;

	float aSquared = dot(a, a);

	// Closest approach is outside the sphere.
	if(aSquared > rSquared) {
		return false;
	}

	// Calculate distance from plane where ray enters/exits the sphere.
	float h = sqrt(rSquared - aSquared);

	// Calculate intersection point relative to sphere center.
	vec3 i = a - h * d;

	intersection = c + i;
	normal = i/r;
	// We've taken a shortcut here to avoid a second square root.
	// Note numerical errors can make the normal have length slightly different from 1.
	// If you need higher precision, you may need to perform a conventional normalization.

	return true;
}

#if !defined(GPU_PARTICLE_FIELD)
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
#endif

void Caustics(float kBeachLevel, vec3 ws_normal, inout vec3 diffuse_color){
	if(world_vert.y < kBeachLevel + 2.0){ // caustics
		float mult = (kBeachLevel + 2.0 - world_vert.y) / 3.0;

		#if defined(WATERFALL_ARENA)
			mult = mult*0.3+0.3;
		#endif

		#if defined(BEACH)
			float fade_x = -71 + sin(time*0.5)*-1.5;

			if(world_vert.x < fade_x){
				mult *= max(0.0, -fade_x + 1 + world_vert.x);
			}
		#endif

		#if defined(SKY_ARK)
			vec3 pos = vec3(-97.96, 68.4, 101.8);
			mult *= max(0.0,min(1.0, 26.0 - distance(world_vert, pos)));
		#endif

		mult = mult * mult;
		mult = min(1.0, mult);
		vec3 temp = world_vert * 0.2;
		float fade = 0.4;// max(0.0, (0.5 - length(temp))*8.0)* max(0.0, fractal(temp.xz*7.0)+0.3);
		float speed = 0.2;
		float fire = abs(fractal(temp.xz*11.0+time*3.0*speed)+fractal(temp.xy*7.0-time*3.0*speed)+fractal(temp.yz*5.0-time*3.0*speed));
		float flame_amount = max(0.0, 0.5 - (fire*0.5 / pow(fade, 2.0))) * 2.0;
		flame_amount += pow(max(0.0, 0.7-fire), 2.0);

		#if defined(WATER_HORIZON)
			mult *= max(0.0, 0.2-ws_normal.y) * 2.0;
		#elif defined(BEACH)
			mult *= max(0.0, 0.2-ws_normal.y) * 3.0;
		#elif defined(SNOW_EVERYWHERE)
			mult *= min(1.0, max(0.0, 1.0-ws_normal.y)) * 1.0;
		#elif defined(SKY_ARK)
			mult *= min(1.0, max(0.0, 1.0-ws_normal.y)) * 0.5;
		#elif defined(WATERFALL_ARENA)
			mult *= min(1.0, max(0.0, 1.0-ws_normal.y)) * 0.5;
		#endif

		diffuse_color.xyz *= 1.0 + flame_amount * primary_light_color.xyz  * mult;
	}
}

#if defined(SSAO_TEST) && !defined(SKY) && !defined(PARTICLE) && !defined(GPU_PARTICLE_FIELD) && !defined(DEPTH_ONLY)
	float SSAO(vec3 ws_vertex) {
		vec4 proj_test_point = (projection_view_mat * vec4(world_vert, 1.0));
		proj_test_point /= proj_test_point.w;
		proj_test_point.xy += vec2(1.0);
		proj_test_point.xy *= 0.5;
		vec2 uv = proj_test_point.xy;
		float my_depth = LinearizeDepth(gl_FragCoord.z);
		float temp = 0.0;
		float z_threshold = 0.3 * length(ws_vertex);
		float total;
		int num_samples = 32;

		for(int i=0; i<num_samples; ++i){
			float angle = noise(gl_FragCoord.xy) + 6.28318530718 * i / float(num_samples);
			mat2 rot;
			rot[0][0] = cos(angle);
			rot[0][1] = sin(angle);
			rot[1][0] = -sin(angle);
			rot[1][1] = cos(angle);
			vec2 offset;
			float mult = 0.1;
			vec2 dims = (viewport.zw - viewport.xy);
			float aspect = 16.0/9.0;// dims[0]/dims[1];
			offset = rot * vec2(mult, 0.0);
			offset[1] *= aspect;
			float radius = pow(noise(gl_FragCoord.xy*1.3+vec2(i)), 1.0);
			vec2 sample_pos = uv + offset * radius;

			if(sample_pos[0] > 0.0 && sample_pos[0] < 1.0 && sample_pos[1] > 0.0 && sample_pos[1] < 1.0) {
				float depth = LinearizeDepth(textureLod(tex18, sample_pos, 0.0).r);
				float fade = (depth - (my_depth - z_threshold)) / z_threshold;

				if(fade > -0.99 && fade < 0.99){
					temp += 1.0;//min(1.0, max(0.0, fade));
				}

				total += 1.0;
			}
		}

		float ssao_amplify = 2.0;
		float ssao_amount = (1.0 - temp / total + 0.2) * ssao_amplify - ssao_amplify * 0.5;
		return ssao_amount;

		if(false) {
			out_color.xyz = vec3(ssao_amount) * 0.1;
			out_color.a = 1.0;
			return 0.0;
		}
	}
#endif

float CloudShadow(vec3 pos){
	#if defined(TEST_CLOUDS_2) && !defined(DEPTH_ONLY) && !defined(CLOUDS_DO_NOT_CAST_SHADOWS)
		return max(0.0, fractal(pos.zx*0.05+vec2(0.0,time*cloud_speed))*2.0+1.0);
	#else
		return 1.0;
	#endif
}


vec3 quat_mul_vec3(vec4 q, vec3 v) {
	// Adapted from https://github.com/g-truc/glm/blob/master/glm/detail/type_quat.inl
	// Also from Fabien Giesen, according to - https://blog.molecular-matters.com/2013/05/24/a-faster-quaternion-vector-multiplication/
	vec3 quat_vector = q.xyz;
	vec3 uv = cross(quat_vector, v);
	vec3 uuv = cross(quat_vector, uv);
	return v + ((uv * q.w) + uuv) * 2;
}


void main(){
	vec3 ws_vertex = world_vert - cam_pos;

	if(frag_tex_coords.x < 0.0){
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

	out_color = vec4(0.0);

	// decal/light cluster stuff
	#if !(defined(NO_DECALS) || defined(DEPTH_ONLY))
		uint decal_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z);
		uint decal_val = texelFetch(cluster_buffer, int(decal_cluster_index)).x;
		uint decal_count = (decal_val >> COUNT_BITS) & COUNT_MASK;
	#endif  // NO_DECALS

	uint light_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z) + 1u;

	#if defined(DEPTH_ONLY)
		uint light_val = 0U;
	#else
		uint light_val = texelFetch(cluster_buffer, int(light_cluster_index)).x;
	#endif //DEPTH_ONLY

	#if defined(NO_INSTANCE_ID)
		int instance_id = 0;
	#endif

	vec4 instance_color_tint = GetInstancedColorTint(instance_id);
	vec2 base_tex_coords = frag_tex_coords;
	vec2 pixelated_coord;
	vec2 texture_size = textureSize(tex0, 0);
	float pixels = texture_size.y;

	pixelated_coord.x = (floor(base_tex_coords.x * pixels) / pixels + ceil(base_tex_coords.x * pixels) / pixels) / 2.0f;
	pixelated_coord.y = (floor(base_tex_coords.y * pixels) / pixels + ceil(base_tex_coords.y * pixels) / pixels) / 2.0f;

	float frames = texture_size.x / pixels;
	float max_frames = frames;

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

	float animation_progress = mod(time / 1.0, 1.0);
	pixelated_coord.x /= frames;
	pixelated_coord.x += (1.0f / frames) * floor(animation_progress * max_frames);

	vec4 colormap = textureLod(tex0, pixelated_coord, 0.0);

	if(colormap.a < 0.1){
		discard;
	}

	vec4 shadow_coords[4];

	#if !defined(DEPTH_ONLY)
		shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
		shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
		shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
		shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
	#endif

	#if defined(DEPTH_ONLY)
		out_color = vec4(vec3(1.0), 1.0);
		return;
	#else

		#if defined(TANGENT)
			vec3 ws_normal;
			vec4 normalmap = texture(normal_tex,tc0);

			{
				vec3 unpacked_normal = UnpackTanNormal(normalmap);

				ws_normal = normalize(quat_mul_vec3(GetInstancedModelRotationQuat(instance_id), tan_to_obj * unpacked_normal));

				}
			#else
				vec4 normalmap = texture(tex1,tc0);
				vec3 os_normal = UnpackObjNormal(normalmap);
				vec3 ws_normal = quat_mul_vec3(GetInstancedModelRotationQuat(instance_id), os_normal);
			#endif

			#if !defined(WATER)
				colormap.xyz *= instance_color_tint.xyz;
			#endif


		#if !defined(PLANT)
			#if defined(ALPHA)
				float spec_amount = normalmap.a;
			#else
				float spec_amount = colormap.a;

				#if !defined(CHARACTER) && !defined(ITEM) && !defined(METALNESS_PBR)
					spec_amount = GammaCorrectFloat(spec_amount);
				#endif
			#endif
		#endif

		float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));

		float preserve_wetness = 1.0;
		float ambient_mult = 1.0;
		float env_ambient_mult = 1.0;

		vec3 flame_final_color = vec3(0.0, 0.0, 0.0);
		float flame_final_contrib = 0.0;

		vec3 decal_diffuse_color = vec3(0.0);

		#if !defined(NO_DECALS)
			#if defined(INSTANCED_MESH)
				vec4 old_colormap = colormap;
				float old_spec_amount = spec_amount;
			#endif

			{
				CalculateDecals(colormap, ws_normal, spec_amount, roughness, preserve_wetness, ambient_mult, env_ambient_mult, decal_diffuse_color, world_vert, time, decal_val, flame_final_color, flame_final_contrib);
			}

			#if defined(INSTANCED_MESH)
				if(instance_color_tint[3] == -1.0){
					colormap = old_colormap;
					ambient_mult = 1.0;
				}
			#endif
		#endif

		#if defined(ALBEDO_ONLY)
			out_color = vec4(colormap.xyz,1.0);

			return;
		#endif

		vec3 shadow_tex = vec3(1.0);

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

		shadow_tex.r *= CloudShadow(world_vert);

		#if defined(WATERFALL)
			ws_normal = vec3(0,0.5,0);
		#endif

		CALC_DIRECT_DIFFUSE_COLOR

		diffuse_color += decal_diffuse_color;  // Is zero if decals aren't enabled

		bool use_amb_cube = false;
		bool use_3d_tex = false;
		vec3 ambient_cube_color[6];

		for(int i=0; i<6; ++i){
			ambient_cube_color[i] = vec3(0.0);
		}

		vec3 ambient_color = vec3(0.0);

		// Screen space reflection test
		#if !defined(SIMPLE_WATER)
			#define SCREEN_SPACE_REFLECTION
		#endif

		#if defined(SSAO_TEST)
			env_ambient_mult *= SSAO(ws_vertex);
		#endif

		diffuse_color += ambient_color * GetAmbientContrib(shadow_tex.g) * ambient_mult * env_ambient_mult;

		vec3 spec_color = vec3(0.0);

		float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));

		float reflection_roughness = roughness;
		roughness = mix(0.00001, 0.9, roughness);
		float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);

		spec *= 100.0* mix(1.0, 0.01, roughness);

		spec_color = primary_light_color.xyz * vec3(spec);
		vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));

		#if defined(SCREEN_SPACE_REFLECTION) && defined(WATER)
			vec3 reflection_color = screen_space_reflect;
		#else
			#if defined(NO_REFLECTION_CAPTURE)
				vec3 reflection_color = vec3(1.0);
			#else
				vec3 reflection_color = LookUpReflectionShapes(ref_cap_cubemap, world_vert, spec_map_vec, reflection_roughness * 3.0) * ambient_mult * env_ambient_mult;
			#endif
		#endif

		spec_color += reflection_color;

		float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
		float base_reflectivity = spec_amount;
		float fresnel = pow(glancing, 4.0) * (1.0 - roughness) * 0.05;
		float spec_val = mix(base_reflectivity, 1.0, fresnel);
		spec_amount = spec_val;

		colormap.xyz *= mix(vec3(1.0),instance_color_tint.xyz,normalmap.a);

		#if defined(DAMP_FOG) || defined(RAINY) || defined(MISTY) || defined(VOLCANO) || defined(WATERFALL_ARENA) || defined(SKY_ARK) || defined(SHADOW_POINT_LIGHTS)
			ambient_mult *= env_ambient_mult;
		#endif

		CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);

		vec3 color = mix(diffuse_color * colormap.xyz, spec_color, 0.0);
		float haze_amount = GetHazeAmount(ws_vertex, haze_mult);
		vec3 fog_color;
		fog_color = SampleAmbientCube(ambient_cube_color, ws_vertex * -1.0);

		fog_color *= GetFogColorMult();

		#if defined(FIRE_DECAL_ENABLED) && !defined(NO_DECALS)
			color.xyz = mix(color.xyz, flame_final_color, flame_final_contrib);
		#endif // FIRE_DECAL_ENABLED

		color = mix(color, fog_color, haze_amount);
		out_color = vec4(color,1.0);

	#endif // DEPTH_ONLY

}
