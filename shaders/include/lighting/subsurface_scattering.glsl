#if !defined INCLUDE_SSS
    #define INCLUDE_SSS

    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/math/convenience.glsl"

    // courtesy of @belmu from the shaderLABS discord
    void approximate_sss_depth(vec4 shadow_position_clip, out float sss_depth) {
        for (int idx = 0; idx < SSS_SAMPLE_COUNT; idx += 1) {
            vec2 shadow_sample_uv_offset = compute_vogel_disk_sample_uv(idx, SSS_SAMPLE_COUNT); // in texel size
            vec3 shadow_sample_uv_distorted = distort_shadow_clip_position(shadow_position_clip.xyz);
            float depth = sample_colortex(shadowtex0, shadow_sample_uv_distorted.xy, shadow_sample_uv_offset).r;

            sss_depth += max0(shadow_sample_uv_distorted.z - depth);
        }

        sss_depth = (-shadowProjectionInverse[2].z * max(0.001, sss_depth)) / (rcp(SHADOW_DISTANCE_MULTIPLIER) * SSS_SAMPLE_COUNT);
    }
#endif
