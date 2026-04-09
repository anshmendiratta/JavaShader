#if !defined INCLUDE_SSS
    #define INCLUDE_SSS

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/phase_functions.glsl"

    #include "/include/math/convenience.glsl"

    float _approximate_sss_depth(vec4 frag_shadow_position_clip);

    // TODO: complete this
    vec3 approximate_material_sss(Material material, vec3 frag_position_world, vec3 to_light_direction, vec3 from_view_direction) {
        if (material.sss <= EPSILON) return vec3(0.0);

        vec3 frag_position_feet = frag_position_world - cameraPosition;
        vec3 frag_position_shadow_view = (shadowModelView * vec4(frag_position_feet, 1.0)).xyz;
        vec4 frag_position_shadow_clip = shadowProjection * vec4(frag_position_shadow_view, 1.0);
        float sss_depth = _approximate_sss_depth(frag_position_shadow_clip);

        // apply beer lambert law: absorption = constant * absorbance * concentration * path_length.
        // we determine the absorbance using phase functions.
        // we also use the same idea that darker albedos have lower sss
        vec3 optical_density = material.albedo * 0.5 - 1.0; // map [0.0, 1.0] to something negative /shrug
        vec3 beer = clamp01(exp(optical_density * sss_depth * rcp(max_eps(material.sss)))); // TODO: figure out why noble DIVIDES by material.sss instead of multiplying

        // TODO: determine if henyey greenstein is the best phase function for sss
        // this comes mostly from https://github.com/BelmuTM/Noble/blob/a738e4a2cc905f6480286701827f92af959079c3/shaders/include/fragment/brdf.glsl
        float cos_theta = dot(to_light_direction, from_view_direction);
        vec3 isotropic_scattering = beer * _phase_isotropic();
        vec3 forward_scattering = beer * _phase_henyey_greenstein(cos_theta, 0.5);
        vec3 backward_scattering = beer * _phase_henyey_greenstein(cos_theta, -0.5);

        return SSS_STRENGTH * mix(isotropic_scattering, mix(forward_scattering, backward_scattering, 0.5), 0.5);
    }

    // courtesy of @belmu from the shaderLABS discord
    float _approximate_sss_depth(vec4 frag_position_shadow_clip) {
        vec2 frag_position_shadow_screen = (frag_position_shadow_clip.xyz / frag_position_shadow_clip.w * 0.5 + 0.5).xy;

        float sss_depth = 0.0;
        for (int idx = 0; idx < SSS_SAMPLE_COUNT; idx += 1) {
            vec2 sample_position_shadow_screen_uv_offset = compute_vogel_disk_sample_uv(idx, SSS_SAMPLE_COUNT) * texelSize; // in texel size
            vec2 sample_position_shadow_screen_uv = frag_position_shadow_screen + sample_position_shadow_screen_uv_offset;
            vec3 sample_position_shadow_screen = vec3(sample_position_shadow_screen_uv, texture(shadowtex0, sample_position_shadow_screen_uv).r);
            vec4 sample_position_shadow_clip = shadow_screen_to_shadow_clip(sample_position_shadow_screen);

            sample_position_shadow_clip.xy /= _compute_distortion_factor(sample_position_shadow_clip.xy);
            sample_position_shadow_screen = sample_position_shadow_clip.xyz / sample_position_shadow_clip.w * 0.5 + 0.5;

            float depth = texture(shadowtex0, sample_position_shadow_screen.xy).r;

            sss_depth += max0(sample_position_shadow_screen.z - depth); // max0 instead of abs disallows sss materials hidden behind other blocks from being lit from sss
        }

        return sss_depth / (SHADOW_DISTANCE_MULTIPLIER * SSS_SAMPLE_COUNT);
    }
#endif
