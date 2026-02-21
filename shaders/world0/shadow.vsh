#version 330 compatibility

in vec2 mc_midTexCoord;
in vec2 mc_Entity;

out vec2 uv;
out vec4 glcolor;

#include "/lib/settings.glsl"
#include "/include/uniforms.glsl"
#include "/include/shadows/distort.glsl"
#include "/include/vertex/water_waves.glsl"
#include "/include/utility/noise.glsl"

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    gl_Position = ftransform();

    #if WAVING_FOLIAGE == 1
    // Waving foliage.
    // TODO: foliage "jitters" when the camera does.
    vec3 vertex_shadow_view_space_position = (shadowProjectionInverse * gl_Position).xyz;
    vec3 vertex_feet_space_position = (shadowModelViewInverse * vec4(vertex_shadow_view_space_position, 1.0)).xyz;
    vec3 vertex_world_space_position = vertex_feet_space_position + cameraPosition;
    vec3 vertex_offset_world_space = vec3(0.0, 0.0, 0.0);

    // TODO: Make look nicer.
    if (mc_Entity.x == 10000.0) { // Rooted foliage.
        if (uv.y < mc_midTexCoord.y) {
            vertex_offset_world_space = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(
                        sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.xy / 3.0),
                        0.0,
                        sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.zx / 3.0)
                    );
        }
    } else if (mc_Entity.x == 10001.0) { // Leaves.
        vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.xy),
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.yz),
                    sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.zx)
                );
    } else if (mc_Entity.x == 10002.0) { // Water.
        vertex_offset_world_space = WATER_WAVE_AMPLITUDE * vec3(
                    0.0,
                    compute_wave_displacement(vertex_world_space_position.xz, 3),
                    0.0
                );
    }

    // Apply offset(s).
    vec3 vertex_offset_shadow_view_space = mat3(shadowModelView) * vertex_offset_world_space;
    vertex_shadow_view_space_position += vertex_offset_shadow_view_space;
    gl_Position = shadowProjection * vec4(vertex_shadow_view_space_position, 1.0);
    #endif

    gl_Position.xyz = distort_shadow_clip_space_position(gl_Position.xyz);
}
