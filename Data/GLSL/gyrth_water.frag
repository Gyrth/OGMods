#pragma transparent
#pragma blendmode_add

#include "object_shared.glsl"
#include "object_frag.glsl"

uniform float time;

UNIFORM_COMMON_TEXTURES
VARYING_TAN_TO_WORLD
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT
UNIFORM_AVG_COLOR4
uniform float detail_scale;
VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;
varying vec3 bitangent;

void main()
{        
	float a = tc0.y * 2.0;
	float tm = time * 3.0 * color_tint.g;
	vec2 tc0_nv = tc0;

	tc0_nv.y -= tm;
	tc0_nv.x += sin(tc0_nv.y + tm * 0.2) * 0.2;
	a -= cos(tc0_nv.x * 3.141 * 10.0 + tm * 0.4 + sin(tc0_nv.y)) * 0.3 + 0.4;

	vec3 ws_normal;
	vec4 normalmap = texture2D(normal_tex,tc0_nv);
	{
	    vec3 unpacked_normal = UnpackTanNormal(normalmap);
	    ws_normal = tangent_to_world * unpacked_normal;
	}

    vec4 colormap = texture2D(color_tex, tc0_nv);
	float fresnel = pow(max(dot(normalize(-ws_normal), normalize(ws_vertex)), 0.0), 3.0);
	//gl_FragColor = vec4(colormap.r + 0.4, colormap.g + 0.4, colormap.b + 0.1, min(max(pow(max(0.0, colormap.r - a + 0.5), 32.0 * color_tint.r), 0.0), 1.0) * fresnel * color_tint.b);

	gl_FragColor = vec4(colormap.r + 0.0, colormap.g + 0.0, colormap.b + 0.0, min(max(pow(max(0.0, colormap.r - a + 0.5), 1.0 * color_tint.r), 0.0), 1.0) * fresnel * color_tint.b);
	//gl_FragColor = vec4(dot(normalize(ws_normal), normalize(ws_vertex)) + 0.3, 0.3, 0.3, 0.5);
    //CALC_FINAL_UNIVERSAL(max(1.0 - pow(a, 2.0), 0.0))
}
