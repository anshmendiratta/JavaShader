#version 430 compatibility

#include "/include/uniforms.glsl"
#include "/include/settings.glsl"

#include "/include/utility/space_conversions.glsl"

#include "/include/math/vectors.glsl"

out vec4 glcolor;
out vec2 uv;

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    gl_Position = ftransform();

    // scale light source
    vec4 light_source_position_clip_space = view_to_clip(shadowLightPosition);
    vec4 vertex_to_center_clip_space = gl_Position - light_source_position_clip_space;
    vertex_to_center_clip_space *= SUN_MOON_SIZE_SCALAR;

    // rotate light source
    vec3 player_to_sun_vector_clip_space = mat3(gbufferProjection) * sunDirVector;
    vertex_to_center_clip_space = rotate_vector_axis_angle(vertex_to_center_clip_space, player_to_sun_vector_clip_space, SUN_MOON_AXIS_ROTATION);

    vec4 modified_vertex_clip_space = light_source_position_clip_space + 1.5 * vertex_to_center_clip_space;
    gl_Position = modified_vertex_clip_space;

    glcolor = gl_Color;
}
