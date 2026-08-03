#if !defined INCLUDE_SHADOWS_COMPUTE
    #define INCLUDE_SHADOWS_COMPUTE

    #include "/include/pipeline.glsl"
    #include "/include/settings.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/utility/dither.glsl"
    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/shadows/distort.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    // bias taken from bliss: https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/lib/Shadows.glsl#L2, which was in turn taken from comp. reimagined and rethinking voxels
    void _xonk_gri_emin_shadow_fix(inout vec3 frag_world_position, in vec3 frag_world_normal, in float lightmap_sky);
    vec3 _emin_comp_reimagined_bias(vec3 position, vec3 normal, float n_dot_l, float skylight);
    void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal);

    vec3 _get_shadow(in vec3 shadow_screen_position);
    bool _frag_is_shadowed(in vec3 shadow_screen_position);

    // --------------------------
    //     Shadow computation
    // --------------------------

    vec3 compute_shadow(in vec4 shadow_clip_position, vec3 normal_world, float lightmap_sky) {
        // bias
        vec3 frag_world_position = (shadowModelViewInverse * vec4((shadowProjectionInverse * shadow_clip_position).xyz, 1.0)).xyz + cameraPosition;
        float n_dot_l = dot(mat3(gbufferModelViewInverse) * worldLightVector, normal_world);
        frag_world_position += _emin_comp_reimagined_bias(frag_world_position, normal_world, n_dot_l, lightmap_sky); // FIX: fix. apparently too much in some cases. leaves some normals lit
        shadow_clip_position = feet_to_shadow_clip(frag_world_position - cameraPosition);

        float distortFactor = _get_distortion_factor(shadow_clip_position.xy);
        const float bias_size = (shadowDistance / shadowMapResolution) * 4.0;
        shadow_clip_position.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * normal_world.xyz) * distortFactor * bias_size;

        float dither = compute_dither(gl_FragCoord.xy);
        float rotation_angle = dither * TAU;
        mat2 rotation_matrix = mat2(cos(rotation_angle), -sin(rotation_angle), sin(rotation_angle), cos(rotation_angle));

        // NOTE: none of the pcss is physically accurate
        // pcss search
        float pcss_acumulator = 0.; // in depth
        uint blockers_used = 0;
        for (uint idx = 0; idx < PCSS_SAMPLES; idx += 1) { // just adjacent pixels
            vec2 vogel_sample = rotation_matrix * PCSS_SEARCH_RADIUS * compute_vogel_disk_sample_uv(idx, SHADOW_BLUR_SAMPLES) / shadowMapResolution;
            vec4 sample_uv_sclip = shadow_clip_position + vec4(vogel_sample, 0., 0.);
            distort_shadow_clip_position(sample_uv_sclip.xyz);
            vec3 sample_uv = shadow_clip_to_shadow_screen(sample_uv_sclip);

            float sample_depth = texture(shadowtex0, sample_uv.xy).r;
            float blocker_dist = max0(sample_uv.z - sample_depth);

            pcss_acumulator += blocker_dist;
            blockers_used += blocker_dist > 0. ? 1 : 0;
        }

        const float MIN_BLUR_RADIUS = 0.1;
        const float MAX_BLUR_RADIUS = 128.;
        float pcss_avg_dist = blockers_used > 0 ? pcss_acumulator / float(blockers_used) : 0.;
        float blur_radius = mix(MIN_BLUR_RADIUS, MAX_BLUR_RADIUS, pcss_avg_dist); // sqrt so the effect is more apparent.

        vec3 pcf_accumulator = vec3(0.);
        for (uint idx = 0; idx < SHADOW_BLUR_SAMPLES; idx += 1) {
            vec2 vogel_sample = blur_radius * compute_vogel_disk_sample_uv(idx, SHADOW_BLUR_SAMPLES) / shadowMapResolution;
            vec2 rotated_sample = rotation_matrix * vogel_sample;
            vec2 sample_uv_offset = rotated_sample;

            vec4 sample_uv_sclip = shadow_clip_position + vec4(sample_uv_offset, 0.0, 0.0);
            distort_shadow_clip_position(sample_uv_sclip.xyz);
            vec3 sample_uv_sscreen = shadow_clip_to_shadow_screen(sample_uv_sclip);

            pcf_accumulator += _get_shadow(sample_uv_sscreen);
        }

        return pcf_accumulator / float(SHADOW_BLUR_SAMPLES);
    }

    vec3 compute_contact_shadow(in vec3 frag_pos_screen) {
        vec3 frag_pos_view = screen_to_view(frag_pos_screen);

        vec3 raymarch_dir_screen = view_to_screen(shadowLightPosition) - frag_pos_screen;
        raymarch_dir_screen /= max_of(raymarch_dir_screen);
        raymarch_dir_screen *= CONTACT_SHADOW_STEP_SIZE;
        raymarch_dir_screen.xy /= windowDimensions;

        bool intersection = true;
        vec3 raymarched_pos_screen = frag_pos_screen + raymarch_dir_screen;

        for (uint idx = 0; idx < CONTACT_SHADOW_STEPS; idx += 1) {
            float depth = texelFetch(depthtex0, ivec2(windowDimensions * raymarched_pos_screen.xy), 0).x;
            float linear_depth = depth_to_z(depth);
            float linear_raymarched_depth = depth_to_z(raymarched_pos_screen.z);

            float proportional_gap = abs(linear_depth - linear_raymarched_depth) / abs(depth_to_z(far) - depth_to_z(near));

            if (proportional_gap <= 1e-1) {
                float min_linear_depth = linear_raymarched_depth - 1e-2 * depth_to_z(raymarch_dir_screen.z);
                float max_linear_depth = linear_raymarched_depth + 1e-2 * depth_to_z(raymarch_dir_screen.z);

                if (linear_depth <= max_linear_depth && linear_depth >= min_linear_depth && !frag_is_hand(depth)) {
                    return vec3(0.);
                }
            }

            raymarched_pos_screen += raymarch_dir_screen;
        }

        return vec3(1.);
    }

    // ---------------------
    //     Shadow biases
    // ---------------------

    // from complementary reimagined by Emin
    // - https://github.com/ComplementaryDevelopment/ComplementaryReimagined
    vec3 _emin_comp_reimagined_bias(vec3 position, vec3 normal, float n_dot_l, float skylight) {
        return 0.25 * normal * clamp01(0.12 * 0.01 * length(position)) * (2. - clamp01(n_dot_l));
    }

    void _xonk_gri_emin_shadow_fix(inout vec3 frag_world_position, in vec3 frag_world_normal, in float skylight) {
        float minimum_value = 0.05;
        // give a tiny boost to the distance mulitplier when shadowmap resolution is below 2048.0
        float shadow_map_res_multiplier = 1.0 + (shadowDistance / 8.0) * (1.0 - min(shadowMapResolution, 2048) / 2048.0) * 0.3;
        float distance_multiplier = max(1.0 - max(1.0 - length(frag_world_position) / shadowDistance, 0.0), minimum_value) * shadow_map_res_multiplier;

        vec3 bias = frag_world_normal * distance_multiplier;

        vec2 scale = vec2(0.5, 0.25); // stop lightleaking by zooming up, centered on blocks
        vec3 zoom_shadow = scale.y - scale.x * fract(frag_world_position + cameraPosition + bias * scale.y);
        if (skylight < 0.1) bias = zoom_shadow;

        frag_world_position += bias;
    }

    void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal) {
        float bias_adjust = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.5;
        float factor = pow3(length(frag_position_shadow_ndc)) * 0.2;

        frag_position_shadow_ndc.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * frag_world_normal) * factor * bias_adjust;
    }

    // ---------------------
    //     Shadow checks
    // ---------------------

    bool _frag_is_shadowed(vec3 shadow_screen_position) {
        return shadow_screen_position.z < texture(shadowtex0, shadow_screen_position.xy).r;
    }

    vec3 _get_shadow(vec3 shadow_screen_position) {
        float is_visible = float(_frag_is_shadowed(shadow_screen_position));
        if (is_visible == 1.0) return vec3(1.0); // Return full sunlight to use for light calculation.

        float is_opaque_shadowed = step(shadow_screen_position.z, texture(shadowtex1, shadow_screen_position.xy).r);
        // TODO: this might need to take into account hcm/metals that have wavelength-dependent f0s so that the shadowed area isnt grayscale and appears to have some kind of "GI" because of specular bounces. might be solved with rsm
        if (is_opaque_shadowed == 0.0) return vec3(0.);

        // shadowed but by transparent objects. tint shadow
        vec4 shadow_color = texture(shadowcolor0, shadow_screen_position.xy);
        float light_passthrough_proportion = 1 - shadow_color.a;

        return shadow_color.rgb * light_passthrough_proportion;
    }
#endif
