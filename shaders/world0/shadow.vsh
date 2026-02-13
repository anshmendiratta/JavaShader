#version 330 compatibility

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse, shadowModelView, shadowProjectionInverse, shadowProjection, shadowModelViewInverse;
uniform vec3 cameraPosition;

uniform float frameTimeCounter, viewWidth, viewHeight;

in vec2 mc_Entity;

out vec2 uv;
out vec4 glcolor;

#include "/lib/settings.glsl"
#include "/common/shadow_distort.glsl"
#include "/common/water_waves.glsl"
#include "/common/noise.glsl"

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    gl_Position = ftransform();

    // Waving foliage.
    vec3 fragment_shadow_view_space_position = (shadowProjectionInverse * gl_Position).xyz;
    vec3 fragment_feet_space_position = (shadowModelViewInverse * vec4(fragment_shadow_view_space_position, 1.0)).xyz;
    vec3 fragment_world_space_position = fragment_feet_space_position + cameraPosition;
    vec3 vertex_offset_world_space = vec3(0.0, 0.0, 0.0);

    if (mc_Entity.x == 10000.0) { // Rooted foliage.
        // TODO: Make look nicer.
        float rng = sample_default_noise(uv + fragment_world_space_position.yx, viewWidth, viewHeight).r;
        vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                    sin(2.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter + rng * 0.0),
                    sin(3.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter + rng * 20.0),
                    0.0
                );
    } else if (mc_Entity.x == 10001.0) { // Leaves.
        vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + fragment_world_space_position.xy),
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + fragment_world_space_position.yz),
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + fragment_world_space_position.zx)
                );
    } else if (mc_Entity.x == 10002.0) { // Water.
        vertex_offset_world_space = WATER_WAVE_AMPLITUDE * vec3(
                    0.0,
                    compute_wave_displacement(fragment_world_space_position.xz, 3),
                    0.0
                );
    }

    // Apply offset(s).
    vec3 vertex_offset_shadow_view_space = mat3(shadowModelView) * vertex_offset_world_space;
    fragment_shadow_view_space_position += vertex_offset_shadow_view_space;
    gl_Position = shadowProjection * vec4(fragment_shadow_view_space_position, 1.0);

    gl_Position.xyz = distort_shadow_clip_space_position(gl_Position.xyz);
}
