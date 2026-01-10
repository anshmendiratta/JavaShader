#version 330 compatibility

#include "/lib/noise.glsl"

// Coordinate space conversions.
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
// Move only upper half of foliage.
uniform vec2 mc_midTexCoord;
// For noise parameters.
uniform float viewWidth;
uniform float viewHeight;
uniform int worldTime;

in vec2 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

// Waving.
const float FOLIAGE_WAVE_OFFSET = 2 / 7;
const float FOLIAGE_WAVE_SPEED = 0.05;
const float FOLIAGE_WAVE_AMPLITUDE = 0.05;

void main() {
    gl_Position = ftransform();

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0); // From the Iris tutorial:  "Minecraft calculates two values that represent how lit a block is: the exposure to emissive blocks (torches, lava, glowstone, etc.) and the exposure to the sky. These values are stored in gl_MultiTexCoord1 as “lightmap coordinates”, where the x channel encodes block exposure and the y channel sky exposure. The actual range of these values varies between Minecraft versions, but by multiplying it by gl_TextureMatrix[1] we instead get it in the approximate range [0.033, 0.97].""
    normal = gl_NormalMatrix * gl_Normal;
    if (mc_Entity.x == 10000.0) {
        normal = gl_NormalMatrix * vec3(0.0, 1.0, 0.0);
    }
    normal = mat3(gbufferModelViewInverse) * normal;
    glcolor = gl_Color;

    // Waving.
    if (mc_Entity.x == 10000.0) {
        // Rooted foliage.
        // TOOD: Figure out why this check doesn't just move one half of the block.
        if (texcoord.y < mc_midTexCoord.y) {
            float texture_distance = length(mc_midTexCoord - texcoord);
            vec3 v_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
            vec3 v_player_space_position = (gbufferModelViewInverse * vec4(v_view_space_position, 1.0)).xyz;
            vec3 v_world_position = v_player_space_position + cameraPosition;
            // Apply wave.
            float noise_sample = sample_default_noise(texcoord + v_world_position.xy, viewWidth, viewHeight).r;
            // TODO: Make look nicer.
            v_world_position.x += sin(2.0 * FOLIAGE_WAVE_SPEED * worldTime + noise_sample) * FOLIAGE_WAVE_AMPLITUDE;
            v_world_position.z -= sin(3.0 * FOLIAGE_WAVE_SPEED * worldTime + 4.0 * noise_sample) * FOLIAGE_WAVE_AMPLITUDE;
            // Undo
            vec3 v_player_space_wave_position = v_world_position - cameraPosition;
            vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
            vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
            gl_Position = v_clip_space_wave_position;
        }
    } else if (mc_Entity.x == 10001.0) {
        // Leaves.
        float texture_distance = length(mc_midTexCoord - texcoord);
        vec3 v_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
        vec3 v_player_space_position = (gbufferModelViewInverse * vec4(v_view_space_position, 1.0)).xyz;
        vec3 v_world_space_position = v_player_space_position + cameraPosition;
        // Apply wave.
        v_world_space_position.x += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(worldTime * FOLIAGE_WAVE_SPEED) + v_world_space_position.xy);
        v_world_space_position.y += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(worldTime * FOLIAGE_WAVE_SPEED) + v_world_space_position.yz);
        v_world_space_position.z += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(worldTime * FOLIAGE_WAVE_SPEED) + v_world_space_position.zx);
        // Undo
        vec3 v_player_space_wave_position = v_world_space_position - cameraPosition;
        vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
        vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
        gl_Position = v_clip_space_wave_position;
    }
}
