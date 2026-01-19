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

in vec2 mc_Entity;
in vec4 at_tangent;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal_feet_space;
out vec3 tangent_feet_space;
// Normal mapping.
out vec3 pbr_normal_feet_space;
out float pbr_ao; // Ambient occlusion.

// Waving.
const float FOLIAGE_WAVE_OFFSET = 2 / 7;
const float FOLIAGE_WAVE_SPEED = 0.5;
const float FOLIAGE_WAVE_AMPLITUDE = 0.09;

#include "/common/utility.glsl"
#include "/lib/settings.glsl"

vec2 pom_texcoord_transform(float pbr_pom_displacement, vec2 texcoord, vec3 view_direction) {
    vec2 p = view_direction.xy / view_direction.z * (pbr_pom_displacement * 1.0); // TODO: Replace 1.0 with HEIGHT_SCALE at some point.

    return texcoord - p;
}

void main() {
    // Exports.
    gl_Position = ftransform();
    glcolor = gl_Color;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from [0.033, 0.97] to [0.0, 1.0].

    normal_feet_space = mc_Entity.x == 10000.0 ? gl_NormalMatrix * vec3(0.0, 1.0, 0.0) : gl_NormalMatrix * gl_Normal; // View space.
    normal_feet_space = mat3(gbufferModelViewInverse) * normal_feet_space; // Feet space.
    #ifdef NORMAL_MAPPING
    tangent_feet_space = at_tangent.w * (gl_NormalMatrix * at_tangent.xyz); // View space.
    tangent_feet_space = mat3(gbufferModelViewInverse) * tangent_feet_space; // Feet space.
    #endif

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
            // float rng = rand(float(frameTimeCounter));
            float rng = sample_default_noise(texcoord + v_world_position.yx, viewWidth, viewHeight).r;
            // TODO: Make look nicer.
            v_world_position.x += sin(2.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter) * FOLIAGE_WAVE_AMPLITUDE;
            v_world_position.z -= sin(3.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter + rng * 20.0) * FOLIAGE_WAVE_AMPLITUDE;
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
        v_world_space_position.x += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.xy);
        v_world_space_position.y += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.yz);
        v_world_space_position.z += FOLIAGE_WAVE_AMPLITUDE * sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + v_world_space_position.zx);
        // Undo
        vec3 v_player_space_wave_position = v_world_space_position - cameraPosition;
        vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
        vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
        gl_Position = v_clip_space_wave_position;
    }
}
