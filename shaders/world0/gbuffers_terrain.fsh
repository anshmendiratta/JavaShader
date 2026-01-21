#version 330 compatibility

uniform sampler2D gtexture; // Texture atlas.
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec3 cameraPosition;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 tangent_view_space;
in vec3 normal_view_space;
in float pbr_ao;

/*
const int colortex15Format = RG32F;
*/

/* RENDERTARGETS: 0,1,2,3,4,15 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec4 encoded_normal;
layout(location = 3) out vec4 encoded_pbr_specular;
layout(location = 4) out vec2 transformed_texcoord;

#include "/common/utility.glsl"
#include "/lib/settings.glsl"

vec2 parallax_mapping(float displacement, vec2 texcoord, vec3 view_direction_tangent_space) {
    float height = displacement;
    vec2 p = view_direction_tangent_space.xy / view_direction_tangent_space.z * (height * 2.0);

    return texcoord - p;
}

void main() {
    lightmap_data = vec4(lmcoord, 0.0, 1.0);
    color = texture(gtexture, texcoord) * glcolor; // Block texture with biome color.

    #ifdef SPECULAR_MAPPING
    encoded_pbr_specular = texture(specular, texcoord); // All positive values -- no transform needed.
    #endif

    #ifdef NORMAL_MAPPING
    vec3 bitangent_view_space = cross(normal_view_space, tangent_view_space);
    mat3 TBN_matrix = mat3(normal_view_space, tangent_view_space, bitangent_view_space);

    #ifdef POM
    // TODO: Fix POM.
    vec3 fragment_ndc_space_position = vec3(texcoord.xy, texture(depthtex0, texcoord).r) * 2.0 - 1.0;
    vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
    vec3 view_direction_view_space = fragment_view_space_position;
    vec3 view_direction_tangent_space = normalize(transpose(TBN_matrix) * view_direction_view_space);
    float pbr_displacement = texture(normals, texcoord).a; // Normal space.
    transformed_texcoord = parallax_mapping(pbr_displacement, texcoord, view_direction_tangent_space);
    color = texture(gtexture, transformed_texcoord) * glcolor; // Replace fragment.
    #endif

    // Unpack.
    vec4 pbr_normal_data = texture(normals,
            #ifdef POM
            transformed_texcoord
            #else
            texcoord
        #endif
        ) * 2.0 - 1.0; // Normal space.
    vec3 pbr_normal_normal_space = vec3(pbr_normal_data.xy, sqrt(1.0 - dot(pbr_normal_data.xy, pbr_normal_data.xy)));
    // Apply.
    vec3 pbr_normal_feet_space = normalize(TBN_matrix * pbr_normal_normal_space);
    encoded_normal = vec4(pbr_normal_feet_space * 0.5 + 0.5, 1.0);
    #else
    // No normal mapping.
    vec3 normal_feet_space = mat3(gbufferModelViewInverse) * normal_view_space;
    encoded_normal = vec4(normal_feet_space * 0.5 + 0.5, 1.0); // Feet space.
    #endif

    // if (transformed_texcoord.x > 1.0 || transformed_texcoord.y > 1.0 || transformed_texcoord.x < 0.0 || transformed_texcoord.y < 0.0)
    //     discard; // Remove artifacting at the edges of the texture.
    if (color.a < alphaTestRef) {
        discard;
    }
}
