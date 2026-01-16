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
    const int samples_count = (2 * SHADOW_RANGE) * (2 * SHADOW_RANGE);
    // Sample noise and construct random rotation matrix.
    float noise_sample = sample_default_noise(texcoord, viewWidth, viewHeight).r; // Randomizing box kernel sampling in soft shadowing.
    float theta = noise_sample * radians(360.0);
    float sin_t = sin(theta);
    float cos_t = cos(theta);
    mat2 rotation = mat2(cos_t, -sin_t, sin_t, cos_t);

    vec3 shadow_accumulator = vec3(0.0);
    for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; /* Increment by one pixel */ x++) {
        for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; /* Increment by one pixel */ y++) {
            vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE); // Sample `samples_count` # of  points within a grid of side length 2 * SHADOW_RADIUS.
            offset = rotation * offset; // Rotate sampling offset.
            offset /= SHADOW_MAP_RESOLUTION; // Resize so offsets are in terms of pixels. Without this division, the offset is in terms of the clip space (i.e., [-1.0, 1.0]^2).
            // Repeat `main` fn coordinate space conversion.
            vec4 shadow_clip_space_position_offset = shadow_clip_space_position + vec4(offset, 0.0, 0.0);
            float shadow_bias = compute_shadow_bias(shadow_clip_space_position_offset.xyz);
            shadow_clip_space_position_offset.z -= shadow_bias;
            shadow_clip_space_position_offset.xyz = distort_shadow_clip_space_position(shadow_clip_space_position_offset.xyz); // Apply distortion to sample shadow map.
            vec3 shadow_space_ndc_position = shadow_clip_space_position_offset.xyz / shadow_clip_space_position_offset.w;
            vec3 shadow_screen_space_position = shadow_space_ndc_position * 0.5 + 0.5; // Conversion from [-1.0, 1.0] to OpenGL's [0.0, 1.0].
            // Add to accumulator.
            shadow_accumulator += get_shadow(shadow_screen_space_position); // Continue previous `main` fn logic including colored/transparent shadows.
        }
    }

    return shadow_accumulator / float(samples_count); // Return average.
}
