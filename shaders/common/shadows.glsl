// REQUIRES:
// - normal
// - shadowModelView, shadowProjection
// - shadowDistance
// - shadowResolution

#include "/lib/pipeline.glsl"
#include "/common/math.glsl"

const float shadowDistance = 160.0;

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

// TODO: Use a better kernel than a box kernel.
vec3 get_soft_shadow(vec4 shadow_clip_space_position, vec3 normal_world_space) {
    const int samples_count = (2 * SHADOW_RANGE) * (2 * SHADOW_RANGE);
    // Sample noise and construct random rotation matrix.
    float noise_sample = sample_default_noise(uv, viewWidth, viewHeight).r; // Randomizing box kernel sampling in soft shadowing.
    float theta = noise_sample * radians(360.0);
    float sin_t = sin(theta);
    float cos_t = cos(theta);
    mat2 rotation = mat2(cos_t, -sin_t, sin_t, cos_t);

    // const float MAX_RANGE = rcp(SHADOW_RADIUS);
    vec3 shadow_accumulator = vec3(0.0);
    for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; /* increment by one pixel */ x++) {
        for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; /* increment by one pixel */ y++) {
            vec2 offset = vec2(x, y) * SHADOW_RADIUS * rcp(float(SHADOW_RANGE)); // Sample `samples_count` # of points within a grid of side length 2 * SHADOW_RADIUS.
            offset = rotation * offset;
            offset /= SHADOW_MAP_RESOLUTION; // Resize so offsets are in terms of pixels. Without this division, the offset is in terms of the clip space (i.e., [-1.0, 1.0]^2).
            vec4 shadow_clip_space_position_offset = shadow_clip_space_position + vec4(offset, 0.0, 0.0);

            // Bias.
            const float shadow_bias = (shadowDistance / shadowMapResolution) * 16.0 * SHADOW_BIAS; // Courtesy of @eldeston (https://discord.com/channels/237199950235041794/525510804494221312/1100010778133794827) in the shaderLABS discord.
            float distortion_factor = compute_distortion_factor(shadow_clip_space_position_offset.xyz);
            shadow_clip_space_position_offset.xyz += (mat3(shadowProjection) *
                    (mat3(shadowModelView) * normal_world_space)) * distortion_factor * shadow_bias; // Offset using normal.
            shadow_clip_space_position_offset.xyz = distort_shadow_clip_space_position(shadow_clip_space_position_offset.xyz); // Apply distortion to sample shadow map.

            // Conversions.
            vec3 shadow_space_ndc_position = shadow_clip_space_position_offset.xyz / shadow_clip_space_position_offset.w;
            vec3 shadow_screen_space_position = shadow_space_ndc_position * 0.5 + 0.5; // Conversion from [-1.0, 1.0] to OpenGL's [0.0, 1.0].
            // Add to accumulator.
            shadow_accumulator += get_shadow(shadow_screen_space_position); // Continue previous `main` fn logic including colored/transparent shadows.
        }
    }

    return shadow_accumulator / float(samples_count); // Return average.
}
