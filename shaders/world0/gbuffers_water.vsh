#version 430 compatibility

in vec2 mc_Entity;

out vec4 glcolor;
out vec2 uv;

#include "/lib/settings.glsl"

#include "/include/uniforms.glsl"
#include "/include/ids.glsl"

#include "/include/vertex/water_waves.glsl"

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    gl_Position = ftransform();
    glcolor = gl_Color;

    if (mc_Entity.x == ID_WATER) {
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
        // gl_Normal = compute_wave_normal(world_space_position.xy, 0.01, 1.0);
    }
}
