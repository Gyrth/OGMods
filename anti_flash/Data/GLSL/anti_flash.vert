#version 150
#extension GL_ARB_shading_language_420pack : enable
#include "lighting150.glsl"

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
uniform mat4 mvp;

out vec2 frag_tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec2 tex_coord;
out vec3 world_vert;
out vec3 frag_normal;
out vec3 model_position;
flat out int instance_id;

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
in vec3 normal_attrib;

void main() {
    instance_id = gl_InstanceID;
	int index = gl_VertexID;

	frag_tex_coords = tex_coord_attrib;

	tex_coord = tex_coord_attrib;
	tex_coord[1] = 1.0 - tex_coord[1];

	vec4 instance_rotation = GetInstancedModelRotationQuat(instance_id);
	vec3 instance_translation = model_translation_attrib;
	vec3 instance_vertex = vertex_attrib;

	#if defined(KEY)
		instance_rotation.x += sin(time) * 0.2;
		instance_rotation.y += sin(time * 0.96) * 0.2;
		instance_rotation.z += sin(time * 0.98) * 0.2;
		instance_vertex.y += sin(time) / 2.0;
	#endif

    vec3 transformed_vertex = transform_vec3(GetInstancedModelScale(instance_id), instance_rotation, instance_translation, instance_vertex);
	model_position = model_translation_attrib;

    world_vert = transformed_vertex;
	frag_normal = normal_attrib;

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
	world_vert = transformed_vertex;
}
