// Textures.
uniform sampler2D colortex0, colortex7; // Bloom.

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

in vec2 uv;

// TODO: Bloom colortex is completely black.
void main() {
    color = texture(colortex0, uv);
    color += texture(colortex7, uv);
}
