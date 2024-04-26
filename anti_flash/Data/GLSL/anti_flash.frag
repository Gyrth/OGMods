#version 150
#extension GL_ARB_shading_language_420pack : enable

#og_version_major 1
#og_version_minor 5

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR

uniform sampler2D base_normal_tex;
#define base_color_tex tex6
in vec3 model_position;

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

#define tc0 frag_tex_coords
#define tc1 base_tex_coord

uniform mat4 shadow_matrix[4];
#define shadow_tex_coords tc1
uniform mat4 projection_view_mat;

in vec3 world_vert;

#pragma bind_out_color
out vec4 out_color;

in vec2 tex_coord;
in vec2 base_tex_coord;
in vec3 orig_vert;
in mat3 tangent_to_world;
in vec3 frag_normal;

uniform float overbright;
const float cloud_speed = 0.1;
const float PI = 3.141592653589793;

uniform int stipple[64];

#include "decals.glsl"

float normalIndicator(vec3 normalEdgeBias, vec3 baseNormal, vec3 newNormal, float depth_diff){
	// Credit: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDiff = dot(baseNormal - newNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
	float depthIndicator = clamp(sign(depth_diff * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(baseNormal, newNormal)) * depthIndicator * normalIndicator;
}

float pattern(vec2 uv_in, vec2 res) {

	vec2 center = vec2(0.0, 0.0);
	float angle = 45.0;
	float scale = 5.0;

	float s = sin(angle);
	float c = cos(angle);
	vec2 uv = uv_in * res - center;
	vec2 point = vec2(
		c * uv.x - s * uv.y,
		s * uv.x + c * uv.y
	) * PI/scale;

	return (sin(point.x) * sin(point.y)) * 4.0;
}

void main() {

    vec3 ws_normal = frag_normal;

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

	//----------------------------------------------------------------------------------

	vec4 instance_color_tint = GetInstancedColorTint(instance_id);
	out_color = vec4(instance_color_tint.rgb, 1.0);
	vec3 highlight_color = vec3(0.0);

	//----------------------------------------------------------------------------------
	//Apply lighting--------------------------------------------------------------------
	//----------------------------------------------------------------------------------

	vec3 ws_vertex = world_vert - cam_pos;
	float roughness = mix(0.7, 1.0, pow((out_color.x + out_color.y + out_color.z) / 3.0, 0.01));
	float spec_amount = out_color.a;
	float preserve_wetness = 1.0;
	float ambient_mult = 1.0;
	float env_ambient_mult = 1.0;
	vec3 flame_final_color = vec3(0.0, 0.0, 0.0);
	float flame_final_contrib = 0.0;

	#if !defined(DEPTH_ONLY)
		vec4 shadow_coords[4];

		shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
		shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
		shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
		shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);

		float shadow = GetCascadeShadow(shadow_sampler, shadow_coords, distance(cam_pos, world_vert));
		out_color.xyz *= mix(0.1, 1.0, shadow);
	#endif

	#if !defined(DEPTH_ONLY) && !defined(NO_DECALS)

		vec3 decal_diffuse_color = vec3(0.0);

		{
			// CalculateDecals(out_color, ws_normal, spec_amount, roughness, preserve_wetness, ambient_mult, env_ambient_mult, decal_diffuse_color, world_vert, time, decal_val, flame_final_color, flame_final_contrib);
		}

		vec3 spec_color = vec3(0.0);
		vec3 light_contrib = out_color.xyz;
		CalculateLightContrib(light_contrib, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);
		out_color.rgb = light_contrib;
		
	#endif

	// vec3 shadow_tex = vec3(0.0);
	// CALC_DIRECT_DIFFUSE_COLOR

	//----------------------------------------------------------------------------------
	// Apply the sketchy lines based on how dark the scene is.--------------------------
	//----------------------------------------------------------------------------------
	float texture_scale = 0.5;
	vec2 viewport_size = textureSize(tex5, 0);
	vec2 texture_size = textureSize(tex0, 0);

	vec2 scaled_uv = gl_FragCoord.xy / (viewport_size / texture_scale);
	scaled_uv = fract(scaled_uv);
	
	if(out_color.r < 0.1){
		// As dark as possible when it's darkest.
		out_color.rgb = highlight_color;
	}else if(out_color.r < 0.25){
		// Stipple when it's a little bit dark.
		float average = (out_color.r + out_color.g + out_color.b) / 3.0;
		// out_color = vec4( vec3(average) * 10.0 - 5.0 + pattern(gl_FragCoord.xy, vec2(8)), 1.0);

		float dot_size = 2.0;
		float value_multiplier = 1.0;
		bool invert = false;

		float fSize = float(64);
		vec2 TEXTURE_PIXEL_SIZE = vec2(1.0 / texture_size);

		vec2 ratio = vec2(1.0, TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y);
		vec2 pixelated_uv = floor(scaled_uv * fSize * ratio) / (fSize * ratio);
		float dots = length(fract(scaled_uv * fSize * ratio) - vec2(0.5)) * dot_size;
		float value = out_color.r;

		dots = mix(dots, 1.0 - dots, float(invert));
		dots += value * value_multiplier;
		dots = pow(dots, 5.0);
		dots = clamp(dots, 0.0, 1.0);
		out_color.rgb = vec3(dots);
	}else if(out_color.r < 0.6){
		vec4 lines_tex = textureLod(tex0, fract(tex_coord * 5.0), 0.0) * 20.0;
		// Vertical lines when it's little bit darker.
		out_color.rgb = mix(vec3(1.0), highlight_color, lines_tex.g * (out_color.r * 2.0));
	}

	#if defined(KEY)
		out_color.rgb = vec3(1.0, 0.0, 0.0);
	#endif

	//----------------------------------------------------------------------------------
	// Add edges-------------------------------------------------------------------------
	//----------------------------------------------------------------------------------
	vec3 model_scale = GetInstancedModelScale(instance_id);
	float highest_scale = max(model_scale.x, max(model_scale.y, model_scale.z));
	float line_size = distance(cam_pos, model_position);
	vec2 pixel_size = vec2(1.0 / texture_size) * line_size / highest_scale;

	vec2 base_tex_coords = tex_coord;
	vec2 pixelated_coord;
	float pixels = texture_size.y;

	pixelated_coord.x = (floor(base_tex_coords.x * pixels) / pixels + ceil(base_tex_coords.x * pixels) / pixels) / 2.0;
	pixelated_coord.y = (floor(base_tex_coords.y * pixels) / pixels + ceil(base_tex_coords.y * pixels) / pixels) / 2.0;

	float normal_diff = 0.0;
	float depth_diff = 0.0;
	float lod = 0.0;
	vec3 normal = texture(tex1, pixelated_coord).rgb * 2.0 - 1.0;
	// vec3 normal = textureLod(tex1, pixelated_coord, lod).rgb * 2.0 - 1.0;

	vec3 nu = textureLod(tex1, pixelated_coord + vec2(0., -1.) * pixel_size, lod).rgb * 2.0 - 1.0;
	vec3 nr = textureLod(tex1, pixelated_coord + vec2(1., 0.) * pixel_size, lod).rgb * 2.0 - 1.0;
	vec3 nd = textureLod(tex1, pixelated_coord + vec2(0., 1.) * pixel_size, lod).rgb * 2.0 - 1.0;
	vec3 nl = textureLod(tex1, pixelated_coord + vec2(-1., 0.) * pixel_size, lod).rgb * 2.0 - 1.0;

	vec3 normal_edge_bias = (vec3(1., 1., 1.));

	normal_diff += normalIndicator(normal_edge_bias, normal, nu, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nr, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nd, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nl, depth_diff);
	normal_diff = smoothstep(0.2, 0.8, normal_diff);
	normal_diff = clamp(normal_diff, 0.0, 1.0);

	out_color.rgb = mix(out_color.rgb, highlight_color, normal_diff);

	#if defined(KEY)
		out_color.rgb = vec3(1.0, 0.0, 0.0);
	#endif

	// out_color.rgb = highlight_color;
	
	//----------------------------------------------------------------------------------
}
