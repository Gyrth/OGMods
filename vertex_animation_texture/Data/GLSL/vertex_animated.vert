#version 460 core
#extension GL_ARB_shader_storage_buffer_object : enable
#extension GL_ARB_shader_draw_parameters : enable
#include "lighting150.glsl"

out vec2 frag_tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec3 world_vert;
flat out int instance_id;
out vec3 vertex_color;

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

uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform float time;

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;

uniform sampler2D tex0; // ColorMap
uniform sampler2D tex1; // Normalmap
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;// TranslucencyMap / WeightMap
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;

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
	vec3 bounds = vec3(5.0, 5.0, 5.0);
	float freq = 1.5f;
	// float x_frame_position = (instances[gl_InstanceID].color_tint.r);
	float x_frame_position = 0.5f * (sin((time) / freq)) + 0.5;
	vec3 rest_vert = vertex_attrib;
	int index = gl_VertexID;
	vec3 last_vertex_position = vec3(1000.0f, 1000.0f, 1000.0f);
	float expected_vertex_count = 85.0f;
	float top_white_pixel = 84.0f;
	float texture_height = 84.0f;
	vec3 animated_vertex_position = vec3(0.0);

	float y_frame_position = index;
	vec2 texture_size_1 = textureSize(tex1, 0);
	vec2 texture_size_2 = textureSize(tex5, 0);
	float x_center_offset = 1.0 / texture_size_1.x;
	float y_center_offset = 1.0 / texture_size_1.y;

	for(int i = 0; i <= 83; i++){
		int x_pixel = i;
		float x_pos = 1.0 / (texture_size_1.x / 2.0) * x_pixel;

		int y_pixel = 0;
		float y_pos = 1.0 / (texture_size_1.y / 2.0) * y_pixel;

		vec4 color_value_1 = textureLod(tex1, vec2(x_pos + x_center_offset, y_pos + y_center_offset), 0.0);
		vec4 color_value_2 = textureLod(tex5, vec2(x_pos + x_center_offset, y_pos + y_center_offset), 0.0);

		float position_x = DecodeFloatRG(vec2(color_value_1.x, color_value_2.x));
		float position_y = DecodeFloatRG(vec2(color_value_1.y, color_value_2.y));
		float position_z = DecodeFloatRG(vec2(color_value_1.z, color_value_2.z));

		vec3 vertex_position = vec3(position_x, position_y, position_z);
		vertex_position = vertex_position * bounds.x;
		vertex_position = vertex_position - (bounds / 2.0f);
		vertex_position = vec3(vertex_position.x, vertex_position.z, vertex_position.y * -1.0f);

		if(distance(rest_vert, vertex_position) < distance(rest_vert, last_vertex_position)){
			last_vertex_position = vertex_position;
			index = i;
		}
	}

	int x_pixel = index;
	float x_pos = 1.0 / (texture_size_1.x / 2.0) * x_pixel;

	int y_pixel = 90;
	float y_pos = 1.0 / (texture_size_1.y / 2.0) * y_pixel;

	float animation_speed = 0.15f;
	float animation_length = 160.0f;
	float range = animation_length / (texture_size_1.y / 2.0);
	float skip_first_frame = 1.0 / (texture_size_1.y / 2.0);
	float animation_progress = mod((time * animation_speed) / range, range) + skip_first_frame;
	y_pos = animation_progress;

	vec4 color_value_1 = textureLod(tex1, vec2(x_pos + x_center_offset, y_pos + y_center_offset), 0.0);
	vec4 color_value_2 = textureLod(tex5, vec2(x_pos + x_center_offset, y_pos + y_center_offset), 0.0);

	float position_x = DecodeFloatRG(vec2(color_value_1.x, color_value_2.x));
	float position_y = DecodeFloatRG(vec2(color_value_1.y, color_value_2.y));
	float position_z = DecodeFloatRG(vec2(color_value_1.z, color_value_2.z));

	vec3 vertex_position = vec3(position_x, position_y, position_z);
	vertex_position = vertex_position * bounds.x;
	vertex_position = vertex_position - (bounds / 2.0f);
	vertex_position = vec3(vertex_position.x * -1.0f, vertex_position.z * -1.0f, vertex_position.y * 1.0f);

	animated_vertex_position = vertex_position;

	// vertex_color = color_value_2.xyz;
	vertex_color = index < 23.0 ? vec3(1.0, 0.0, 0.0) : vec3(1.0);

	instance_id = gl_InstanceID;

	vec3 transformed_vertex = transform_vec3(GetInstancedModelScale(instance_id), GetInstancedModelRotationQuat(instance_id), model_translation_attrib, vertex_attrib);
	transformed_vertex += animated_vertex_position;

	frag_tex_coords = tex_coord_attrib;
	frag_tex_coords[1] = 1.0 - frag_tex_coords[1];

	world_vert = transformed_vertex;
	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
}
