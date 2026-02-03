#version 330 compatibility

out vec2 uv;
out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main() {
    gl_Position = ftransform();
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0)); // Check if white.
}