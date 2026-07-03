#if !defined INCLUDE_RSM
    #define INCLUDE_RSM

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/pipeline.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/vogel_disk_blur.glsl"

    // resources:
    //     https://users.soe.ucsc.edu/~pang/160/s13/proposal/mijallen/proposal/media/p203-dachsbacher.pdf
    //     https://github.com/jbritain/glint-shaders/blob/a92967eedd3bb0928d32b6545059df3e6a548bfe/shaders/lib/lighting/reflectiveShadowMapping.glsl#L22

    // TODO: probably broken. integrate shadow map distortion
    vec3 compute_rsm_gi(vec3 fragment_normal_world) {
        if (fragment_is_hand(uv)) return vec3(0.0);

        vec3 fragment_position_screen = vec3(uv, texture(depthtex0, uv).r);
        vec3 fragment_position_view = screen_to_view(fragment_position_screen);
        vec3 fragment_position_feet = view_to_feet(fragment_position_view);
        vec3 fragment_position_shadow_view = feet_to_shadow_view(fragment_position_feet);
        vec4 fragment_position_shadow_clip = shadow_view_to_shadow_clip(fragment_position_shadow_view);
        vec3 fragment_position_shadow_screen = shadow_clip_to_shadow_screen(fragment_position_shadow_clip);

        distort_shadow_clip_position(fragment_position_shadow_clip.xy);
        vec3 fragment_position_shadow_view_distorted = shadow_clip_to_shadow_view(fragment_position_shadow_clip_distorted);

        vec3 fragment_normal_shadow_view = mat3(shadowModelView) * fragment_normal_world;

        float dither = compute_dither(gl_FragCoord.xy);
        const float radius = RSM_SAMPLE_RADIUS * rcp(shadowDistance);

        vec3 irradiance = vec3(0.0);
        for (uint idx = 0; idx < RSM_SAMPLE_COUNT; idx += 1) {
            vec2 offset = sqrt(radius) * compute_vogel_disk_sample_uv(idx, RSM_SAMPLE_COUNT);

            vec2 sample_position_shadow_screen_uv = fragment_position_shadow_screen.xy + offset;
            vec3 sample_position_shadow_screen = vec3(sample_position_shadow_screen_uv, texture(shadowtex0, sample_position_shadow_screen_uv).r);
            vec3 sample_position_shadow_view = shadow_screen_to_shadow_view(sample_position_shadow_screen); // for distance func
            vec4 sample_position_shadow_clip = shadow_view_to_shadow_clip(sample_position_shadow_view);
            distort_shadow_clip_position(sample_position_shadow_clip.xy);
            vec3 sample_position_shadow_screen_distorted = shadow_clip_to_shadow_screen(sample_position_shadow_clip_distorted);

            vec3 sample_position_shadow_view_distorted = shadow_clip_to_shadow_view(sample_position_shadow_clip_distorted);
            vec3 direction = -(fragment_position_shadow_view - sample_position_shadow_view); // TODO: negation?

            vec4 sample_color = texture(shadowcolor0, sample_position_shadow_screen_distorted.xy);
            vec3 sample_flux = rgb_to_linear(sample_color.a * sample_color.rgb);
            vec3 sample_normal_world = texture(shadowcolor1, sample_position_shadow_screen_distorted.xy).xyz * 2.0 - 1.0;
            vec3 sample_normal_shadow_view = mat3(shadowModelView) * sample_normal_world;
            float sample_weight = max(0.0, 1.0 - (length(offset) / (RSM_SAMPLE_RADIUS * rcp(shadowDistance))));

            irradiance +=
                sample_flux *
                    max0(dot(direction, sample_normal_shadow_view)) *
                    max0(dot(-direction, fragment_normal_shadow_view)) *
                    rcp(pow4(length(direction)) + 1.0);
        }

        irradiance /= float(RSM_SAMPLE_COUNT);
        irradiance *= PI * RSM_SAMPLE_RADIUS * pow(RSM_BRIGHTNESS, 3.0); // TODO: dont know what normalization term should exist here

        return irradiance;
    }
#endif
