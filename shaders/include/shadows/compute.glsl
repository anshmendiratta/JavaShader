#if !defined INCLUDE_SHADOWS_COMPUTE
    #define INCLUDE_SHADOWS_COMPUTE

    #include "/lib/pipeline.glsl"
    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/vogel_disk_blur.glsl"

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

    #define SHADOW_BLUR_SAMPLE_COUNT SHADOW_RANGE * SHADOW_RANGE

    // TODO: blur this properly bruh. still bands
    vec3 get_soft_shadow(vec4 shadow_clip_space_position, vec3 normal_world_space) {
        // Courtesy of @eldeston (https://discord.com/channels/237199950235041794/525510804494221312/1100010778133794827) in the shaderLABS discord.
        const float shadow_bias = (shadowDistance / shadowMapResolution) * 16.0 * SHADOW_BIAS;

        vec3 shadow_accumulator = vec3(0.0);

        for (int idx = 0; idx < SHADOW_BLUR_SAMPLE_COUNT; idx += 1) {
            vec2 sample_uv_offset = rcp(SHADOW_MAP_RESOLUTION) * rcp(SHADOW_RANGE) * SHADOW_RADIUS * compute_vogel_disk_sample_uv(idx, SHADOW_BLUR_SAMPLE_COUNT);
            vec4 sample_uv = shadow_clip_space_position + vec4(sample_uv_offset, 0.0, 0.0);

            float distortion_factor = compute_distortion_factor(sample_uv.xyz);
            sample_uv.xyz += (mat3(shadowProjection) *
                    (mat3(shadowModelView) * normal_world_space)) * distortion_factor * shadow_bias; // normal offset
            // TODO: temporary shadow bias fix below.
            sample_uv.z -= 0.001;
            sample_uv.xyz = distort_shadow_clip_space_position(sample_uv.xyz);

            vec3 uv_space_ndc_position = sample_uv.xyz / sample_uv.w;
            vec3 uv_screen_space_position = uv_space_ndc_position * 0.5 + 0.5;

            shadow_accumulator += get_shadow(uv_screen_space_position);
        }

        return shadow_accumulator / float(SHADOW_BLUR_SAMPLE_COUNT); // Return average.
    }

#endif
