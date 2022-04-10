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

const vec3 bounds = vec3(10.0, 10.0, 10.0);

// UNIFORM_DETAIL4_TEXTURES
//
// UNIFORM_AVG_COLOR4

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

float distSquared( vec3 A, vec3 B )
{

	vec3 C = A - B;
	return dot( C, C );

}

int GetIndex(vec3 vertex){
	int x_num = int( (vertex.x < 0.0? vertex.x * -1.0 : vertex.x) * 10000.001 );
	int y_num = int( (vertex.y < 0.0? vertex.y * -1.0 : vertex.y) * 10000.001 );
	int z_num = int( (vertex.z < 0.0? vertex.z * -1.0 : vertex.z) * 10000.001 );

	int x_tens = (x_num % 100) / 10;
	int x_units = (x_num % 10);

	int y_tens = (y_num % 100) / 10;
	int y_units = (y_num % 10);

	int z_tens = (z_num % 100) / 10;
	int z_units = (z_num % 10);

	int arr[6] = int[6](x_tens, x_units, y_tens, y_units, z_tens, z_units);
	int result = 0;

	for(int i = 0 ; i < arr.length() ; i++){
		result = (result * 10) + arr[i];
	}

	return result;
}

void main() {
	vec3 rest_vert = vertex_attrib;
	int index = -1;
	vec3 last_vertex_position = vec3(0.0f, 0.0f, 0.0f);
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

	vec2 texture_size_1 = textureSize(tex1, 0);
	int target_resolution = int(texture_size_1.x / texture_mult);
	float half_pixel_offset = (1.0 / target_resolution) / 2.0;

	for(int i = 0; i <= int(texture_size_1.x); i++){
		int x_pixel = i;
		float x_pos = 1.0 / target_resolution * x_pixel;

		int y_pixel = 1;
		float y_pos = 1.0 / target_resolution * y_pixel;

		vec4 color_1 = textureLod(tex1, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);
		vec4 color_2 = textureLod(tex5, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);

		vec3 vertex_position;
		vertex_position.x = DecodeFloatRG(vec2(color_1.x, color_2.x));
		vertex_position.y = DecodeFloatRG(vec2(color_1.y, color_2.y));
		vertex_position.z = DecodeFloatRG(vec2(color_1.z, color_2.z));

		vertex_position = vertex_position * bounds.x;
		vertex_position = vertex_position - (bounds / 2.0f);
		// vertex_position = vec3(vertex_position.x * 1.0, vertex_position.z * 1.0, vertex_position.y * -1.0f);

		float dist = distance(rest_vert, vertex_position);
		// float dist = sqrt(distSquared(rest_vert, vertex_position));

		// Get the index based comparing rounded vertex positions.
		// vec3 rounded_rest = vec3(ceil(rest_vert.x * 1000.0) / 1000.0, ceil(rest_vert.y * 1000.0) / 1000.0, ceil(rest_vert.z * 1000.0) / 1000.0);
		// vec3 rounded_vertex = vec3(ceil(vertex_position.x * 1000.0) / 1000.0, ceil(vertex_position.y * 1000.0) / 1000.0, ceil(vertex_position.z * 1000.0) / 1000.0);

		// if(rounded_rest == rounded_vertex){
		if(dist < 0.01){
			index = i;
			break;
		}
	}

	int x_pixel = index;
	float x_pos = 1.0 / target_resolution * x_pixel;

	//Not used
	int y_pixel = 90;
	float y_pos = 1.0 / target_resolution * y_pixel;

	vec4 settings_color_1 = textureLod(tex1, vec2(half_pixel_offset, half_pixel_offset), 0.0);
	vec4 settings_color_2 = textureLod(tex5, vec2(half_pixel_offset, half_pixel_offset), 0.0);

	vec3 settings;
	settings.x = DecodeFloatRG(vec2(settings_color_1.x, settings_color_2.x));
	settings.y = DecodeFloatRG(vec2(settings_color_1.y, settings_color_2.y));
	settings.z = DecodeFloatRG(vec2(settings_color_1.z, settings_color_2.z));

	float animation_length = int(settings.x * 10000.0);
	float animation_speed = 0.0021;
	// float animation_speed = 1.0;
	// float animation_speed = 24.0 / animation_length;
	// float animation_speed =  ((texture_size_1.y - 2.0) / animation_length) / 24.0;
	// float animation_speed = (animation_length / (texture_size_1.y - 2.0)) * (1.0 / 24.0);

	float range = animation_length / (texture_size_1.y / texture_mult);
	float skip_frames = half_pixel_offset * 4.0f;

	float position_offset = model_translation_attrib.x + model_translation_attrib.z;

	float animation_progress = mod((time * animation_speed + position_offset) / range, range) + skip_frames;
	y_pos = animation_progress;

	vec4 color_1 = textureLod(tex1, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);
	vec4 color_2 = textureLod(tex5, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset), 0.0);
	// vec3 color_1 = plant_stability_attrib;

	vec3 vertex_position;
	vertex_position.x = DecodeFloatRG(vec2(color_1.x, color_2.x));
	vertex_position.y = DecodeFloatRG(vec2(color_1.y, color_2.y));
	vertex_position.z = DecodeFloatRG(vec2(color_1.z, color_2.z));

	vertex_position = vertex_position * bounds.x;
	vertex_position = vertex_position - (bounds / 2.0f);
	// vertex_position = vec3(vertex_position.x * 1.0f, vertex_position.z * 1.0f, vertex_position.y * -1.0f);

	animated_vertex_position = vertex_attrib - vertex_position;

	if(skip_render == 1){
		skip_render = 0;
		animated_vertex_position = vertex_attrib;
	}

	instance_id = gl_InstanceID;

	// vertex_color = textureLod(tex24, frag_tex_coords, 0.0).xyz;
	// vertex_color = plant_stability_attrib;
	// vertex_color = vec3(0.0, 0.0, normal_attrib.r);
	// vertex_color = (normal_attrib + vec3(2.0)) / 4.0;

	// vertex_color = color_1.xyz;
	vertex_color = albedo_color.xyz;
	// vertex_color = index <= 34 ? vec3(1.0, 0.0, 0.0) : vec3(1.0);

	vec3 transformed_vertex = transform_vec3(GetInstancedModelScale(instance_id), GetInstancedModelRotationQuat(instance_id), model_translation_attrib, animated_vertex_position);

	// transformed_vertex = vertex_attrib;
	// frag_normal = normal_attrib;
	// world_vert = transformed_vertex;

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
}
