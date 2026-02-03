#version 330 compatibility

// ----------
// Bloom Application.
// ----------

// Textures.
uniform sampler2D colortex0;
uniform sampler2D colortex5; // Bloom.

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

in vec2 uv;

// TODO: Bloom colortex is completely black.
void main() {
    color = texture(colortex0, uv);

    vec3 bloom = texture(colortex5, uv).rgb;
    if (length(bloom) > 0.5) {
        color.rgb += bloom;
    }
}