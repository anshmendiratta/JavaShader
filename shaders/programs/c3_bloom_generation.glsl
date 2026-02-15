// Textures.
uniform sampler2D colortex0;

uniform int viewWidth, viewHeight;

in vec2 uv;

/* RENDERTARGETS: 0,6 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bloom_texel;

const float BLOOM_THRESHOLD = 1.0;

// TODO: Bloom colortex is completely black.
void main() {
    color = texture(colortex0, uv);
    // Filter out bright texel.
    float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    bloom_texel = brightness > BLOOM_THRESHOLD ? color : vec4(0.0);
}
