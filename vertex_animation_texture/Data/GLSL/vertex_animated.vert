#version 450 core

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

out vec2 frag_tex_coords;
out vec2 tex_coords;
out mat3 tangent_to_world;
out vec3 orig_vert;
out vec3 world_vert;

flat out int instance_id;

out vec4 vertex_color;
out vec3 frag_normal;

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

const float SRGB_GAMMA = 1.0 / 2.2;
const float SRGB_INVERSE_GAMMA = 2.2;
const float SRGB_ALPHA = 0.055;

float DecodeFloatRG(vec2 enc){
	vec2 kDecodeDot = vec2(1.0, 1.0 / 256.0);
	return dot(enc, kDecodeDot);
}

vec2 EncodeFloatRG(float v){
	vec2 kEncodeMul = vec2(1.0, 255.0);
	float kEncodeBit = 1.0 / 255.0;
	vec2 enc = kEncodeMul * v;

	enc.x = mod(enc.x, 1.0);
	enc.y = mod(enc.y, 1.0);

	enc.x -= enc.y * kEncodeBit;

	return enc;
}

// Converts a single linear channel to srgb
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
        return 12.92 * channel;
    else
        return (1.0 + SRGB_ALPHA) * pow(channel, 1.0/2.4) - SRGB_ALPHA;
}

// Converts a linear rgb color to a srgb color (exact, not approximated)
vec4 rgba_to_srgb(vec4 rgba) {
    return vec4(
        linear_to_srgb(rgba.r),
        linear_to_srgb(rgba.g),
        linear_to_srgb(rgba.b),
		rgba.a
    );
}

// Converts a linear rgb color to a srgb color (approximated, but fast)
vec3 rgb_to_srgb_approx(vec3 rgb) {
    return pow(rgb, vec3(SRGB_GAMMA));
}

vec4 NormalizeColor(in vec4 value){
  vec4 denorm = value * 255.0;
  vec4 rounded = round(denorm);
  return rounded / 255.0;
}

vec4 GammaCorrect(vec4 value){
	float gamma = 2.2;
    return vec4(pow(value.rgb, vec3(1.0 / gamma)), value.a);
}

vec4 GammaUnCorrect(vec4 value){
	float gamma = 1.0 / 2.2;
	return vec4(255 * pow(value.r / 255, gamma), 255 * pow(value.g / 255, gamma), 255 * pow(value.b / 255, gamma), value.a);
}

// Converts a color from linear light gamma to sRGB gamma
vec4 fromLinear(vec4 linearRGB)
{
    bvec4 cutoff = lessThan(linearRGB, vec4(0.0031308));
    vec4 higher = vec4(1.055)*pow(linearRGB, vec4(1.0/2.4)) - vec4(0.055);
    vec4 lower = linearRGB * vec4(12.92);

    return mix(higher, lower, cutoff);
}

// Converts a color from sRGB gamma to linear light gamma
vec4 toLinear(vec4 sRGB)
{
    bvec4 cutoff = lessThan(sRGB, vec4(0.04045));
    vec4 higher = pow((sRGB + vec4(0.055))/vec4(1.055), vec4(2.4));
    vec4 lower = sRGB/vec4(12.92);

    return mix(higher, lower, cutoff);
}

void main() {
	instance_id = gl_InstanceID;
	int index = gl_VertexID;

	frag_tex_coords = tex_coord_attrib;
	frag_tex_coords[1] = 1.0 - frag_tex_coords[1];

	vertex_color = texture(tex5, frag_tex_coords);
	vec4 normal_color = texture(tex1, frag_tex_coords);

	vec2 texture_size = textureSize(tex0, 0);
	float target_resolution = int(texture_size.y);
	float one_pixel_offset = (1.0 / target_resolution);
	float half_pixel_offset = (1.0 / target_resolution) / 2.0;

	int x_pixel = index;
	float x_pos = 1.0 / target_resolution * x_pixel;
	float animation_length = 24.0;

	vec4 tint = GetInstancedColorTint(instance_id);
	float range = 24.0 / texture_size.y;

	float position_offset = length(texture(tex0, vec2(model_translation_attrib.x, model_translation_attrib.z)));
	position_offset = tint.r;
	float animation_speed = 2.25;

	float animation_progress = mod((time * animation_speed + position_offset) * range, range);
	float settings_skip = one_pixel_offset + one_pixel_offset;
	float y_pos = animation_progress + settings_skip;

	// Use half a pixel to get the center of the pixel.
	vec4 color_1 = texture(tex0, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset));
	vec4 color_2 = texture(tex0, vec2(x_pos + half_pixel_offset, y_pos + half_pixel_offset + (one_pixel_offset * animation_length)));

	color_1 = fromLinear(color_1);
	color_2 = fromLinear(color_2);

	vec3 vertex_position;
	vertex_position.x = DecodeFloatRG(vec2(color_1.x, color_2.x));
	vertex_position.y = DecodeFloatRG(vec2(color_1.y, color_2.y));
	vertex_position.z = DecodeFloatRG(vec2(color_1.z, color_2.z));

	vertex_position = vertex_position * bounds.x;
	vertex_position = vertex_position - (bounds / 2.0f);

	vec3 animated_vertex_position = vertex_attrib - vertex_position;
	vec3 transformed_vertex = transform_vec3(GetInstancedModelScale(instance_id), GetInstancedModelRotationQuat(instance_id), model_translation_attrib, animated_vertex_position);

	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
	world_vert = transformed_vertex;
}
