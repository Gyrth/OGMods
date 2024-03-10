#version 150
#extension GL_ARB_shading_language_420pack : enable

in vec2 vert_attrib;
out vec2 tex;

void main() {    
    tex = vert_attrib;
    vec2 pos = vert_attrib * 2.0 - vec2(1.0);
    gl_Position = vec4(pos[0], pos[1], 0.0 ,1.0);
}
