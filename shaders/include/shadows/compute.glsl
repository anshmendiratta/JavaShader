#if !defined INCLUDE_SHADOWS_COMPUTE
    #define INCLUDE_SHADOWS_COMPUTE

    #include "/include/pipeline.glsl"
    #include "/include/settings.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/dither.glsl"

    #include "/include/shadows/distort.glsl"

    // bias taken from bliss: https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/lib/Shadows.glsl#L2, which was in turn taken from comp. reimagined and rethinking voxels
    void _xonk_gri_emin_shadow_fix(out vec3 frag_world_position, vec3 frag_world_normal, float lightmap_sky); // not necessary with eldeston's normal offset
    void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal); // pretty bad
    vec3 _get_shadow(vec3 shadow_screen_position);
    vec3 _get_soft_shadow(vec4 shadow_clip_position, vec3 normal_world, float lightmap_sky);

    #define SHADOW_BLUR_SAMPLE_COUNT SHADOW_RANGE * SHADOW_RANGE

    vec3 _get_soft_shadow(in vec4 shadow_clip_position, vec3 normal_world, float lightmap_sky) {
        float dither = compute_dither(gl_FragCoord.xy);
        float rotation_angle = dither * TAU;
        mat2 rotation_matrix = mat2(cos(rotation_angle), -sin(rotation_angle), sin(rotation_angle), cos(rotation_angle));

        vec3 frag_world_position = (shadowModelViewInverse * vec4((shadowProjectionInverse * shadow_clip_position).xyz, 1.0)).xyz + cameraPosition;

        // biases
        // _xonk_gri_emin_shadow_fix(frag_world_position, normal_world, lightmap_sky); // seems useless with normal offsets
        shadow_clip_position = shadow_view_to_shadow_clip(feet_to_shadow_view(frag_world_position - cameraPosition));
        // eldeston's normal bias offset
        float distortion_factor = _compute_distortion_factor(shadow_clip_position.xy);
        const float base_bias = (shadowDistance / shadowMapResolution) * 4.0;
        shadow_clip_position.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * normal_world.xyz) * distortion_factor * base_bias;

        vec3 shadow_accumulator = vec3(0.0);
        for (int idx = 0; idx < SHADOW_BLUR_SAMPLE_COUNT; idx += 1) {
            vec2 vogel_sample = compute_vogel_disk_sample_uv(idx, SHADOW_BLUR_SAMPLE_COUNT);
            vec2 rotated_sample = rotation_matrix * vogel_sample;
            vec2 sample_uv_offset = SHADOW_RADIUS * rotated_sample * rcp(SHADOW_MAP_RESOLUTION) * rcp(SHADOW_RANGE);

            vec4 sample_uv = shadow_clip_position + vec4(sample_uv_offset, 0.0, 0.0);
            sample_uv = distort_shadow_clip_position(sample_uv);

            vec3 sample_uv_shadow_screen = shadow_clip_to_shadow_screen(sample_uv);

            shadow_accumulator += _get_shadow(sample_uv_shadow_screen);
        }

        return shadow_accumulator / float(SHADOW_BLUR_SAMPLE_COUNT);
    }

    // comments are not my own
    void _xonk_gri_emin_shadow_fix(out vec3 frag_world_position, vec3 frag_world_normal, float lightmap_sky) {
        float minimum_value = 0.05;
        // give a tiny boost to the distance mulitplier when shadowmap resolution is below 2048.0
        float shadow_map_res_multiplier = 1.0 + (shadowDistance / 8.0) * (1.0 - min(shadowMapResolution, 2048) / 2048.0) * 0.3;
        float distance_multiplier = max(1.0 - max(1.0 - length(frag_world_position) / shadowDistance, 0.0), minimum_value) * shadow_map_res_multiplier;

        vec3 bias = frag_world_normal * distance_multiplier;

        vec2 scale = vec2(0.5, 0.25); // stop lightleaking by zooming up, centered on blocks
        vec3 zoom_shadow = scale.y - scale.x * fract(frag_world_position + cameraPosition + bias * scale.y);
        if (lightmap_sky < 0.1) bias = zoom_shadow;

        frag_world_position += bias;
    }

    void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal) {
        float bias_adjust = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.5;
        float factor = pow3(length(frag_position_shadow_ndc)) * 0.2;

        frag_position_shadow_ndc.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * frag_world_normal) * factor * bias_adjust;
    }

    vec3 _get_shadow(vec3 shadow_screen_position) {
        float is_visible = step(shadow_screen_position.z, texture(shadowtex0, shadow_screen_position.xy).r);
        if (is_visible == 1.0) {
            // Since the object is in view of the light source, there is no shadow at all."
            return vec3(1.0); // Return full sunlight to use for light calculation.
        }

        float is_opaque_shadowed = step(shadow_screen_position.z, texture(shadowtex1, shadow_screen_position.xy).r);
        // TODO: this might need to take into account hcm/metals that have wavelength-dependent f0s so that the shadowed area isnt grayscale and appears to have some kind of "GI" because of specular bounces. might be solved with rsm
        if (is_opaque_shadowed == 0.0) {
            // The object is obstructed by something fully opaque since we sample from shadowtex1."
            return vec3(0.0); // Full shadow.
        }

        // At this point, the object is neither fully shadowed nor fully visible, so there must be some transparency.
        vec4 shadow_color = texture(shadowcolor0, shadow_screen_position.xy);
        float light_passthrough_proportion = 1 - shadow_color.a;

        return shadow_color.rgb * light_passthrough_proportion;
    }
#endif
