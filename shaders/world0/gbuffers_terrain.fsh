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
in vec2 uv;
in vec2 texture_bottom_left; // vec2(x_min, y_min).
in vec2 single_tex_size; // vec2(x_range, y_range).
in vec4 glcolor;
in vec3 tangent_view_space;
in vec3 normal_view_space;

/*
const int colortex5Format = RG16F;
const int colortex2Format = RGB16;
*/

// For POM looking smoother (mode can be anything but 'nearest').
#ifdef TEXTURE_FILTERING
uniform int textureFilteringMode = 2;
#endif

/* RENDERTARGETS: 0,1,2,3,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmap_data;
layout(location = 2) out vec3 encoded_normal;
layout(location = 3) out vec4 encoded_pbr_specular;
layout(location = 4) out vec2 transformed_uv;

#include "/lib/settings.glsl"
#include "/common/utility.glsl"
#if POM == 1
#include "/common/parallax.glsl"
#endif

void main() {
    lightmap_data = vec4(lmcoord, 0.0, 1.0);

    vec3 bitangent_view_space = normalize(cross(tangent_view_space, normal_view_space));
    mat3 TBN_matrix = mat3(tangent_view_space, bitangent_view_space, normal_view_space);
    #if POM == 1
    // TODO: Fix POM.
    vec3 fragment_ndc_space_position = vec3(uv, texture(depthtex0, uv).r) * 2.0 - 1.0;
    vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
    vec3 view_direction_view_space = normalize(fragment_view_space_position);
    vec3 view_direction_tangent_space = transpose(TBN_matrix) * view_direction_view_space;
    vec2 local_uv = atlas_uv_to_local(uv, texture_bottom_left, single_tex_size);
    mat2 uv_gradient = mat2(dFdx(uv), dFdy(uv));
    vec2 pom_local_uv = pom_uv_transform(local_uv, view_direction_tangent_space, uv_gradient);
    vec2 pom_atlas_uv = local_uv_to_atlas(pom_local_uv, texture_bottom_left, single_tex_size);
    transformed_uv = pom_atlas_uv;
    color = texture(gtexture, transformed_uv) * glcolor; // Replace fragment.
    #else
    color = texture(gtexture, uv) * glcolor; // Block texture with biome color.
    #endif

    #if SPECULAR_MAPPING == 1
    encoded_pbr_specular = texture(specular,
            #if POM == 1
            transformed_uv
            #else
            uv
        #endif
        ); // All positive values -- no transform needed.
    #endif

    #if NORMAL_MAPPING == 1
    // Unpack.
    vec4 pbr_normal_data = texture(normals,
            #if POM == 1
            transformed_uv
            #else
            uv
        #endif
        ) * 2.0 - 1.0; // Normal space.
    vec3 pbr_normal_normal_space = vec3(pbr_normal_data.xy, sqrt(1.0 - dot(pbr_normal_data.xy, pbr_normal_data.xy)));
    // Apply.
    vec3 pbr_normal_view_space = normalize(TBN_matrix * pbr_normal_normal_space);
    vec3 pbr_normal_world_space = mat3(gbufferModelViewInverse) * pbr_normal_view_space;
    encoded_normal = pbr_normal_world_space * 0.5 + 0.5;
    #else
    // No normal mapping.
    vec3 normal_world_space = mat3(gbufferModelViewInverse) * normal_view_space;
    encoded_normal = normal_world_space * 0.5 + 0.5;
    #endif

    if (color.a < alphaTestRef) {
        discard;
    }
}
