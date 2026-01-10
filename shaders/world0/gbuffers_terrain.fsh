#version 330 compatibility

uniform sampler2D gtexture; // Texture atlas.
uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2 */ // Writing to colortex0.
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;

void main() {
    color = texture(gtexture, texcoord) * glcolor; // Block texture with biome color.
    // color /= texture(lightmap, lmcoord); // Default minecraft lighting. Removed since we want to implement our own lighting.
    if (color.a < alphaTestRef) {
        discard;
    }

    // Store in gbuffers.
    lightmap_data = vec4(lmcoord, 0.0, 1.0);
    encoded_normal = vec4(normal * 0.5 + 0.5, 1.0);
}
