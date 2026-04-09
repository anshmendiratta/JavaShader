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
    vec3 approximate_material_sss(Material material, vec3 frag_position_world, vec3 to_light_direction, vec3 to_view_direction) {
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
        float cos_theta = dot(normalize(to_light_direction), normalize(to_view_direction));
        vec3 isotropic_scattering = beer * _phase_isotropic();
        vec3 forward_scattering = beer * _phase_henyey_greenstein(cos_theta, 0.5);
        vec3 backward_scattering = beer * _phase_henyey_greenstein(cos_theta, -0.5);

        return SSS_STRENGTH * mix(isotropic_scattering, mix(forward_scattering, backward_scattering, 0.5), 0.5);
    }

    // courtesy of @belmu from the shaderLABS discord
    float _approximate_sss_depth(in vec4 frag_position_shadow_clip) {
        vec4 frag_position_shadow_clip_distorted = distort_shadow_clip_position(frag_position_shadow_clip);
        float frag_position_depth = shadow_clip_to_shadow_screen(frag_position_shadow_clip_distorted).z;

        float sss_depth = 0.0;
        for (int idx = 0; idx < SSS_SAMPLE_COUNT; idx += 1) {
            vec2 sample_position_offset = compute_vogel_disk_sample_uv(idx, SSS_SAMPLE_COUNT) * texelSize; // in clip space
            vec2 sample_position_uv = frag_position_shadow_clip.xy + sample_position_offset;
            sample_position_uv /= _compute_distortion_factor(sample_position_uv);

            float sample_position_depth = texture(shadowtex0, sample_position_uv).r;

            sss_depth += abs(frag_position_depth - sample_position_depth); // max0 instead of abs disallows sss materials hidden behind other blocks from being lit from sss
        }

        return sss_depth / (SHADOW_DISTANCE_MULTIPLIER * SSS_SAMPLE_COUNT);
    }
#endif
