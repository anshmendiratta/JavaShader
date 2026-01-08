#version 330 compatibility

#include "/lib/shadow_distort.glsl"
#include "/lib/utility.glsl"

// Textures.
uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D shadowtex0; // For shadows cast by all objects.
uniform sampler2D shadowtex1; // For shadows cast *only* by opaque objects.
uniform sampler2D shadowcolor0; // Information about the color, including transparency, of things that cast a shadow.
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Lightmap.
uniform sampler2D colortex2; // Encoded normals.
uniform sampler2D noisetex; // Randomizing box kernel sampling in soft shadowing.

// Other uniforms.
uniform vec3 shadowLightPosition; // Sun/moon position.
uniform mat4 gbufferModelViewInverse; // To convert from view to world/player space.
// For coordinate space conversions to determine the shadowmap sample point.
uniform mat4 gbufferProjectionInverse; 
uniform mat4 shadowModelView; 
uniform mat4 shadowProjection; 
// For texelFetch in shadowing.
uniform float viewWidth; 
uniform float viewHeight; 

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Tell Iris to up the precision of colortex0 so it can store colors properly in the linear color space. If not for this, we would lose some colors since the buffer is meant to store gamma corrected colors. Of course, increasing the precision increases the mem footprint of the buffer, hence increasing the VRAM usage.
// Further, note that this is a multi-line comment so Iris reads it. If it were a single line `//` comment, the below would not work.
/*
const int colortex0format = RGB16;
*/

const vec3 blocklight_color = vec3(1.0, 0.5, 0.08);
const vec3 skylight_color = vec3(0.05, 0.15, 0.3);
const vec3 sunlight_color = vec3(1.0);
const vec3 ambient_color = vec3(0.1);

vec4 sample_noise(vec2 texcoord) {
    ivec2 sample_screen_coord = ivec2(texcoord * vec2(viewWidth, viewHeight));
    ivec2 sample_noise_coord = sample_screen_coord % 256 ; // 256 by default.
    return texelFetch(noisetex, sample_noise_coord, 0);
}

vec3 get_shadow(vec3 shadow_screen_space_position) {
    float is_visible = step(shadow_screen_space_position.z, texture(shadowtex0, shadow_screen_space_position.xy).r);
    if (is_visible == 1.0) {
        // Since the object is in view of the light source, there is no shadow at all."
        return vec3(1.0); // Return full sunlight to use for light calculation.
    }

    float is_opaque_shadowed = step(shadow_screen_space_position.z, texture(shadowtex1, shadow_screen_space_position.xy).r);
    if (is_opaque_shadowed == 0.0) {
        // The object is obstructed by something fully opaque since we sample from shadowtex1."
        return vec3(0.0); // Full shadow.
    }

    // At this point, the object is neither fully shadowed nor fully visible, so there must be some transparency.
    vec4 shadow_color = texture(shadowcolor0, shadow_screen_space_position.xy);
    float light_passthrough_proportion = 1 - shadow_color.a;

    return shadow_color.rgb * light_passthrough_proportion;
}

// TODO: Use a circular kernel instead of a box kernel.
vec3 get_soft_shadow(vec4 shadow_clip_space_position) {
    const float SHADOW_BIAS = 0.001;
    const int samples_count = (2 * SHADOW_RANGE) * (2 * SHADOW_RANGE);
    // Sample noise and construct random rotation matrix.
    float noise_sample = sample_noise(texcoord).r;
    float theta = noise_sample * radians(360.0);
    float sin_t = sin(theta);
    float cos_t = cos(theta);
    mat2 rotation = mat2(cos_t, -sin_t, sin_t, cos_t);

    vec3 shadow_accumulator = vec3(0.0);    
    for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; /* Increment by one pixel */ x++) {
        for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; /* Increment by one pixel */ y++) {
            vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE); // Sample `samples_count` # of  points within a grid of side length 2 * SHADOW_RADIUS.
            offset = rotation * offset; // Rotate sampling offset.
            offset /= shadowMapResolution; // Resize so offsets are in terms of pixels. Without this division, the offset is in terms of the clip space (i.e., [-1.0, 1.0]^2).
            // Repeat `main` fn coordinate space conversion.
            vec4 shadow_clip_space_position_offset = shadow_clip_space_position + vec4(offset, 0.0, 0.0);
            shadow_clip_space_position_offset.z -= SHADOW_BIAS; // Apply shadow.
            shadow_clip_space_position_offset.xyz = distort_shadow_clip_space_position(shadow_clip_space_position_offset.xyz); // Apply distortion to sample shadow map.
            vec3 shadow_space_ndc_position = shadow_clip_space_position_offset.xyz / shadow_clip_space_position_offset.w;
            vec3 shadow_screen_space_position = shadow_space_ndc_position * 0.5 + 0.5; // Conversion from [-1.0, 1.0] to OpenGL's [0.0, 1.0].
            // Add to accumulator.
            shadow_accumulator += get_shadow(shadow_screen_space_position); // Continue previous `main` fn logic including colored/transparent shadows.
        }
    }

    return shadow_accumulator / float(samples_count); // Return average.
}

void main() {
    // Get information from gbuffers.
    vec2 lightmap = texture(colortex1, texcoord).xy;
    vec3 encoded_normal = texture(colortex2, texcoord).xyz;
    vec3 normal = normalize(encoded_normal * 2.0 - 1.0); // Undo encoding from before writing to normal buffer -- convert from [0, 1.0] to [-1.0, 1.0].

    // Assign color (to "main screen gbuffer").
    color = texture(colortex0, texcoord);

    // Do sky pixel check.
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 fragment_ndc_position = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 fragment_ndc_model_view_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_position);
    vec3 fragment_world_space_position = (gbufferModelViewInverse * vec4(fragment_ndc_model_view_position, 1.0)).xyz;
    vec3 shadow_model_view_position = (shadowModelView * vec4(fragment_world_space_position, 1.0)).xyz;
    vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_model_view_position, 1.0);
    vec3 shadow = get_soft_shadow(shadow_clip_space_position);

    // Sun/moon light source.
    vec3 light_vector = normalize(shadowLightPosition);
    vec3 light_vector_in_world_space = mat3(gbufferModelViewInverse) * light_vector;
    float normal_aligned_with_light_vector = dot(normal, light_vector_in_world_space);

    vec3 blocklight = lightmap.r * blocklight_color; // x is blocklight
    vec3 skylight = lightmap.g * skylight_color; // y is skylight
    vec3 sunlight = clamp(normal_aligned_with_light_vector, 0.0, 1.0) * shadow * sunlight_color; // Multiply by the skylight from the light map since if an object is hidden from the sky, the object is also hidden from the sun.
    vec3 ambient = ambient_color;

    color.rgb *= blocklight + skylight + sunlight + ambient;
    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
