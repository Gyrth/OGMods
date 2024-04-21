#version 150
#extension GL_ARB_shading_language_420pack : enable
#include "lighting150.glsl"

in vec3 model_translation_attrib;  // set per-instance. separate from rest because it's not needed in the fragment shader, so is not slow on low-end GPUs

#if defined(ATTRIB_ENVOBJ_INSTANCING)
	in vec3 model_scale_attrib;
	in vec4 model_rotation_quat_attrib;
	in vec4 color_tint_attrib;
	in vec4 detail_scale_attrib;
#endif

#if !defined(ATTRIB_ENVOBJ_INSTANCING)

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
#endif

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

	// vec4 instance_rotation = GetInstancedModelRotationQuat(instance_id);
	mat4 model_mat = instances[gl_InstanceID].model_mat;
	vec3 instance_vertex = vertex_attrib;

	#if defined(KEY)
		model_mat[0][0] += sin(time) * 0.1;
		model_mat[0][1] += sin(time * 0.96) * 0.1;
		model_mat[0][2] += sin(time * 0.98) * 0.1;
		model_mat[1][0] += sin(time * 0.98) * 0.1;
		model_mat[1][2] += sin(time * 0.98) * 0.1;
		instance_vertex.y += sin(time) / 2.0;
	#endif

	vec3 transformed_vertex = (model_mat * vec4(instance_vertex, 1.0)).xyz;

	model_position = model_translation_attrib;

    world_vert = transformed_vertex;
	frag_normal = normal_attrib;

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
	world_vert = transformed_vertex;
}
