#version 330 compatibility

#include "/lib/constants.glsl"

in vec4 glcolor;
out vec4 color;

void main() {
    color = vec4(SKY_COLOR_START, 1.0);
}
