#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform float time;
uniform vec3 cam_pos;

#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR

uniform sampler2D base_normal_tex;
#define base_color_tex tex6

// uniform sampler2D tex1;
// uniform sampler2D tex2;
uniform sampler2D tex3; // Diffuse cubemap
// uniform sampler2D tex4;
// uniform sampler2D tex8;
// uniform sampler2D tex9;
// uniform sampler2D tex10;

// uniform sampler2D base_color_tex;

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

float CloudShadow(vec3 pos){
	#if defined(TEST_CLOUDS_2) && !defined(DEPTH_ONLY) && !defined(CLOUDS_DO_NOT_CAST_SHADOWS)
		return max(0.0, fractal(pos.zx*0.05+vec2(0.0,time*cloud_speed))*2.0+1.0);
	#else
		return 1.0;
	#endif
}

float normalIndicator(vec3 normalEdgeBias, vec3 baseNormal, vec3 newNormal, float depth_diff){
	// Credit: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDiff = dot(baseNormal - newNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDiff), 0.0, 1.0);
	float depthIndicator = clamp(sign(depth_diff * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(baseNormal, newNormal)) * depthIndicator * normalIndicator;
}

void main() {

	float line_size = 1.0;
	vec2 texture_size = textureSize(tex1, 0);
	vec2 pixel_size = vec2(1.0 / texture_size) * line_size;

	vec2 base_tex_coords = tex_coord;
	vec2 pixelated_coord;
	float pixels = texture_size.y;

	pixelated_coord.x = (floor(base_tex_coords.x * pixels) / pixels + ceil(base_tex_coords.x * pixels) / pixels) / 2.0;
	pixelated_coord.y = (floor(base_tex_coords.y * pixels) / pixels + ceil(base_tex_coords.y * pixels) / pixels) / 2.0;

	vec4 colormap = vec4(0.99, 0.99, 0.99, 1.0);
	vec3 highlight_color = vec3(0.025);

	float normal_diff = 0.0;
	float depth_diff = 0.0;
	vec3 normal = texture(tex1, pixelated_coord).rgb * 2.0 - 1.0;

	vec3 nu = texture(tex1, pixelated_coord + vec2(0., -1.) * pixel_size).rgb * 2.0 - 1.0;
	vec3 nr = texture(tex1, pixelated_coord + vec2(1., 0.) * pixel_size).rgb * 2.0 - 1.0;
	vec3 nd = texture(tex1, pixelated_coord + vec2(0., 1.) * pixel_size).rgb * 2.0 - 1.0;
	vec3 nl = texture(tex1, pixelated_coord + vec2(-1., 0.) * pixel_size).rgb * 2.0 - 1.0;

	vec3 normal_edge_bias = (vec3(1., 1., 1.));

	normal_diff += normalIndicator(normal_edge_bias, normal, nu, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nr, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nd, depth_diff);
	normal_diff += normalIndicator(normal_edge_bias, normal, nl, depth_diff);
	normal_diff = smoothstep(0.2, 0.8, normal_diff);
	normal_diff = clamp(normal_diff, 0.0, 1.0);

	out_color = colormap;
	out_color /= 2.0;

	//----------------------------------------------------------------------------------
	//Apply lighting--------------------------------------------------------------------

	vec4 shadow_coords[4];
	shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
	shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
	shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
	shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
	float shadow = GetCascadeShadow(shadow_sampler, shadow_coords, distance(cam_pos,world_vert));
	shadow *= CloudShadow(world_vert);
	out_color.rgb *= mix(0.015, 1.0, shadow);

	//----------------------------------------------------------------------------------
	// Apply the sketchy lines based on how dark the scene is.--------------------------
	float texture_scale = 5.0;
	float red_weight = 0.5;
	float green_weight = 0.5;
	float blue_weight = 0.5;

	vec4 lines_tex = textureLod(tex0, tex_coord * texture_scale, 0.0);
	
	// if(out_color.r < 0.01){
	// 	out_color.rgb += vec3(lines_tex.r * -red_weight);
	// }

	// if(out_color.r < 0.1){
	// 	out_color.rgb += vec3(lines_tex.g * -green_weight);
	// }

	if(out_color.r < 0.25){
		out_color.rgb += vec3(lines_tex.b * -blue_weight);
	}

	//----------------------------------------------------------------------------------
	//Add edges-------------------------------------------------------------------------

	vec3 final = mix(out_color.rgb, highlight_color, normal_diff);
	out_color.rgb = final;
	
}
