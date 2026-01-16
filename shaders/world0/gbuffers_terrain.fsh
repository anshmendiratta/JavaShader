#version 330 compatibility

uniform sampler2D gtexture; // Texture atlas.
uniform sampler2D lightmap;
uniform sampler2D normals;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 tangent_feet_space;
in vec3 normal_feet_space;
// in vec3 pbr_normal_feet_space;
in float pbr_ao;

/* RENDERTARGETS: 0,1,2,3,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
layout(location = 3) out vec4 encoded_pbr_normal;
layout(location = 4) out vec2 transformed_texcoord;

#include "/common/utility.glsl"

void main() {
    lightmap_data = vec4(lmcoord, 0.0, 1.0);
    encoded_normal = vec4(normal_feet_space * 0.5 + 0.5, 1.0); // Feet space.
    color = texture(gtexture, texcoord) * glcolor; // Block texture with biome color.
    transformed_texcoord = texcoord;
    // #ifdef LABPBR_ENABLED
    // Unpack.
    vec4 pbr_normal_data = texture(normals, texcoord); // Normal space.
    pbr_normal_data.xy = pbr_normal_data.xy * 2.0 - 1.0;
    vec3 pbr_normal_normal_space = vec3(pbr_normal_data.xy, sqrt(1.0 - dot(pbr_normal_data.xy, pbr_normal_data.xy)));
    // Construct TBN.
    mat3 TBN_matrix = tbn_normal_tangent(normal_feet_space, tangent_feet_space); // Normal already in feet space.
    // Apply.
    vec3 pbr_normal_feet_space = normalize(TBN_matrix * pbr_normal_normal_space);
    encoded_pbr_normal = vec4(pbr_normal_data.xyz * 0.5 + 0.5, 1.0);
    // encoded_pbr_normal = texture(normals, texcoord);
    // #endif

    if (texcoord.x > 1.0 || texcoord.y > 1.0 || texcoord.x < 0.0 || texcoord.y < 0.0)
        discard; // Remove artifacting at the edges of the texture.
    if (color.a < alphaTestRef) {
        discard;
    }
}
