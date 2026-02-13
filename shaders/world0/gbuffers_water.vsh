#version 330 compatibility

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse, gbufferProjection, gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec2 mc_Entity;

out vec4 glcolor;
out vec2 uv;

#include "/common/water_waves.glsl"
#include "/lib/settings.glsl"

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    gl_Position = ftransform();
    glcolor = gl_Color;

    if (mc_Entity.x == 10002.0) {
        // Water.
        vec3 view_space_position = (gbufferProjectionInverse * gl_Position).xyz;
        vec3 feet_space_position = (gbufferModelViewInverse * vec4(view_space_position, 1.0)).xyz;
        vec3 world_space_position = feet_space_position + cameraPosition;
        // Apply wave.
        world_space_position.y -= WATER_WAVE_AMPLITUDE * compute_wave_displacement(world_space_position.xz, 3);
        // Undo transformations.
        feet_space_position = world_space_position - cameraPosition;
        view_space_position = (gbufferModelView * vec4(feet_space_position, 1.0)).xyz;
        vec4 clip_space_position = (gbufferProjection * vec4(view_space_position, 1.0));

        gl_Position = clip_space_position;
    }
}
