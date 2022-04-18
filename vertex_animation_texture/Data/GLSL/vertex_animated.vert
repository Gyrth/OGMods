#version 150
#extension GL_ARB_shading_language_420pack : enable

#include "lighting150.glsl"
#include "object_vert150.glsl"

vec3 quat_mul_vec3(vec4 q, vec3 v) {
	// Adapted from https://github.com/g-truc/glm/blob/master/glm/detail/type_quat.inl
	// Also from Fabien Giesen, according to - https://blog.molecular-matters.com/2013/05/24/a-faster-quaternion-vector-multiplication/
	vec3 quat_vector = q.xyz;
	vec3 uv = cross(quat_vector, v);
	vec3 uuv = cross(quat_vector, uv);
	return v + ((uv * q.w) + uuv) * 2;
}

vec3 transform_vec3(vec3 scale, vec4 rotation_quat, vec3 translation, vec3 value) {
	vec3 result = scale * value;
	result = quat_mul_vec3(rotation_quat, result);
	result += translation;
	return result;
}

in vec3 model_translation_attrib;  // set per-instance. separate from rest because it's not needed in the fragment shader, so is not slow on low-end GPUs

#if defined(ATTRIB_ENVOBJ_INSTANCING)
	in vec3 model_scale_attrib;
	in vec4 model_rotation_quat_attrib;
	in vec4 color_tint_attrib;
	in vec4 detail_scale_attrib;
#endif

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

vec3 GetInstancedModelScale(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return model_scale_attrib;
	#else
		return instances[instance_id].model_scale;
	#endif
}

vec4 GetInstancedModelRotationQuat(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return model_rotation_quat_attrib;
	#else
		return instances[instance_id].model_rotation_quat;
	#endif
}

vec4 GetInstancedColorTint(int instance_id) {
	#if defined(ATTRIB_ENVOBJ_INSTANCING)
		return color_tint_attrib;
	#else
		return instances[instance_id].color_tint;
	#endif
}

out vec2 frag_tex_coords;
out vec2 tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec3 world_vert;
flat out int instance_id;
out vec3 vertex_color;
out vec3 frag_normal;
flat out int skip_render;

uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform float time;

in vec3 tangent_attrib;
in vec3 bitangent_attrib;
in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
in vec3 normal_attrib;
in vec3 plant_stability_attrib;

uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;

#define weight_tex tex5
#define detail_color tex6
#define detail_normal tex7

// uniform sampler2D tex5;// TranslucencyMap / WeightMap

uniform sampler2D weight_tex;
uniform sampler2DArray detail_color;
uniform vec4 detail_color_indices;
uniform sampler2DArray detail_normal;
uniform vec4 detail_normal_indices;

const vec3 bounds = vec3(20.0, 20.0, 20.0);

float DecodeFloatRG(vec2 enc){
	vec2 kDecodeDot = vec2(1.0, 1.0 / 255.0);
	return dot(enc, kDecodeDot);
}

vec2 EncodeFloatRG(float v){
	vec2 kEncodeMul = vec2(1.0f, 255.0f);
	float kEncodeBit = 1.0 / 255.0;
	vec2 enc = kEncodeMul * v;

	enc.x = mod(enc.x, 1.0f);
	enc.y = mod(enc.y, 1.0f);

	enc.x -= enc.y * kEncodeBit;

	return enc;
}

void main() {
	int index = gl_VertexID;
	vec3 animated_vertex_position = vertex_attrib;
	float texture_mult = 1.0f;

	frag_tex_coords = tex_coord_attrib;
	frag_tex_coords[1] = 1.0 - frag_tex_coords[1];

	vec4 albedo_color = textureLod(tex0, frag_tex_coords, 0.0);
	vec4 normal_color = textureLod(tex1, frag_tex_coords, 0.0);

	if(albedo_color == normal_color){
		skip_render = 1;
		return;
	}else{
		skip_render = 0;
	}

	vec2 texture_size = textureSize(tex1, 0);
	int target_resolution = int(texture_size.x / texture_mult);
	float half_pixel_offset = (1.0 / target_resolution) / 2.0;

	int x_pixel = index;
	float x_pos = 1.0 / target_resolution * x_pixel;

	//Not used
	int y_pixel = 90;
	float y_pos = 1.0 / target_resolution * y_pixel;

	vec4 settings_color_1 = textureLod(tex1, vec2(half_pixel_offset, half_pixel_offset), 0.0);
	vec4 settings_color_2 = textureLod(tex5, vec2(half_pixel_offset, half_pixel_offset), 0.0);

	// The top row of the images is used for settings. Currently only the animation length, but there's room for more features.
	vec3 settings;
	settings.x = DecodeFloatRG(vec2(settings_color_1.x, settings_color_2.x));
	settings.y = DecodeFloatRG(vec2(settings_color_1.y, settings_color_2.y));
	settings.z = DecodeFloatRG(vec2(settings_color_1.z, settings_color_2.z));

	float animation_length = int(settings.x * 10000.0);
	float range = animation_length / (texture_size.y / texture_mult);
	float skip_frames = half_pixel_offset * 4.0f;

	float position_offset = length(texture(tex0, vec2(model_translation_attrib.x, model_translation_attrib.z)));
	float animation_progress = mod((time * 0.1 + position_offset) * range, range) + skip_frames;
	y_pos = animation_progress;

	vec4 color_1 = textureLod(tex1, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);
	vec4 color_2 = textureLod(tex5, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);

	vec3 vertex_position;
	vertex_position.x = DecodeFloatRG(vec2(color_1.x, color_2.x));
	vertex_position.y = DecodeFloatRG(vec2(color_1.y, color_2.y));
	vertex_position.z = DecodeFloatRG(vec2(color_1.z, color_2.z));

	vertex_position = vertex_position * bounds.x;
	vertex_position = vertex_position - (bounds / 2.0f);

	animated_vertex_position = vertex_attrib - vertex_position;

	if(skip_render == 1){
		skip_render = 0;
		animated_vertex_position = vertex_attrib;
	}

	instance_id = gl_InstanceID;
	vertex_color = albedo_color.xyz;

	vec3 transformed_vertex = transform_vec3(GetInstancedModelScale(instance_id), GetInstancedModelRotationQuat(instance_id), model_translation_attrib, animated_vertex_position);

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
}
