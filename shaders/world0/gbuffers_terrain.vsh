#version 330 compatibility

#include "/common/noise.glsl"

// LabPBR.
uniform sampler2D normals, depthtex0;

uniform mat4 gbufferProjection, gbufferModelView, gbufferProjectionInverse, gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec2 mc_midTexCoord;
uniform float viewWidth, viewHeight, frameTimeCounter;
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

    // Waving foliage.
    vec3 vertex_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
    vec3 vertex_player_space_position = (gbufferModelViewInverse * vec4(vertex_view_space_position, 1.0)).xyz;
    vec3 vertex_world_space_position = vertex_player_space_position + cameraPosition;
    vec3 vertex_offset_world_space = vec3(0.0, 0.0, 0.0);

    if (mc_Entity.x == 10000.0) { // Rooted foliage.
        // TOOD: Figure out why this check doesn't just move one half of the block.
        if (uv.y < mc_midTexCoord.y) {
            // TODO: Make look nicer.
            float rng = sample_default_noise(uv + vertex_world_space_position.yx, viewWidth, viewHeight).r;
            vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                        sin(2.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter),
                        0.0,
                        -sin(3.0 * FOLIAGE_WAVE_SPEED * frameTimeCounter + rng * 20.0)
                    );
        }
    } else if (mc_Entity.x == 10001.0) { // Leaves.
        vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                    sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.xy),
                    sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.yz),
                    sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.zx)
                );
    }

    vec3 vertex_offset_view_space = mat3(gbufferModelView) * vertex_offset_world_space;
    vertex_view_space_position += vertex_offset_view_space;
    gl_Position = gbufferProjection * vec4(vertex_view_space_position, 1.0);
}
