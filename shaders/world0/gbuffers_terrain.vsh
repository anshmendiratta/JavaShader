#version 330 compatibility

#include "/common/noise.glsl"

// LabPBR.
uniform sampler2D normals;
uniform sampler2D depthtex0;

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
uniform float frameTimeCounter;
// POM.
uniform ivec2 atlasSize;

in vec2 mc_Entity;
in vec4 at_tangent;

out vec2 lmcoord;
out vec2 uv;
out vec2 texture_bottom_left; // vec2(x_min, y_min).
out vec2 single_tex_size; // vec2(x_range, y_range).
out vec4 glcolor;
out vec3 normal_view_space;
out vec3 tangent_view_space;

// Waving.
const float FOLIAGE_WAVE_OFFSET = 2 / 7;
const float FOLIAGE_WAVE_SPEED = 0.5;
const float FOLIAGE_WAVE_AMPLITUDE = 0.09;

#include "/common/utility.glsl"
#include "/lib/settings.glsl"

void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;

    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec2 half_size = abs(uv - mc_midTexCoord);
    texture_bottom_left = mc_midTexCoord - half_size;
    single_tex_size = half_size * 2.0;

    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from [0.033, 0.97] to [0.0, 1.0].

    normal_view_space = mc_Entity.x == 10000.0 ? gl_NormalMatrix * vec3(0.0, 1.0, 0.0) : normalize(gl_NormalMatrix * gl_Normal); // View space.
    #if NORMAL_MAPPING == 1
    normal_view_space = normalize(gl_NormalMatrix * gl_Normal); // View space.
    tangent_view_space = normalize(at_tangent.w * (gl_NormalMatrix * at_tangent.xyz)); // View space.
    #endif

    // Waving.
    if (mc_Entity.x == 10000.0) { // Rooted foliage.
        // TOOD: Figure out why this check doesn't just move one half of the block.
        if (uv.y < mc_midTexCoord.y) {
            float texture_distance = length(mc_midTexCoord - uv);
            vec3 v_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
            vec3 v_player_space_position = (gbufferModelViewInverse * vec4(v_view_space_position, 1.0)).xyz;
            vec3 v_world_position = v_player_space_position + cameraPosition;
            // Apply wave.
            // float rng = rand(float(frameTimeCounter));
            float rng = sample_default_noise(uv + v_world_position.yx, viewWidth, viewHeight).r;
            // TODO: Make look nicer.
            v_world_position.x += sin(2.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter) * FOLIAGE_WAVE_AMPLITUDE;
            v_world_position.z -= sin(3.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter + rng * 20.0) * FOLIAGE_WAVE_AMPLITUDE;
            // Undo space conversions.
            vec3 v_player_space_wave_position = v_world_position - cameraPosition;
            vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
            vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
            gl_Position = v_clip_space_wave_position;
        }
    } else if (mc_Entity.x == 10001.0) { // Leaves.
        float texture_distance = length(mc_midTexCoord - uv);
        vec3 v_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
        vec3 v_player_space_position = (gbufferModelViewInverse * vec4(v_view_space_position, 1.0)).xyz;
        vec3 v_world_space_position = v_player_space_position + cameraPosition;
        // Apply wave.
        v_world_space_position.x += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.xy);
        v_world_space_position.y += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.yz);
        v_world_space_position.z += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.zx);
        // Undo space conversions.
        vec3 v_player_space_wave_position = v_world_space_position - cameraPosition;
        vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
        vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
        gl_Position = v_clip_space_wave_position;
    }
}
