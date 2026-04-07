#if !defined INCLUDE_RSM
    #define INCLUDE_RSM

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/shadows/distort.glsl"

    // resources:
    //     https://users.soe.ucsc.edu/~pang/160/s13/proposal/mijallen/proposal/media/p203-dachsbacher.pdf
    //     https://github.com/jbritain/glint-shaders/blob/a92967eedd3bb0928d32b6545059df3e6a548bfe/shaders/lib/lighting/reflectiveShadowMapping.glsl#L22

    vec3 compute_rsm_gi(vec3 fragment_normal_world) {
        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 fragment_position_screen = vec3(screen_uv, texture(depthtex0, screen_uv).r);
        vec3 fragment_position_ndc = fragment_position_screen * 2.0 - 1.0;
        vec3 fragment_position_view = ndc_to_view(fragment_position_ndc);
        vec3 fragment_position_feet = view_to_feet(fragment_position_view);

        // Transform to shadow view space
        vec3 fragment_position_shadow_view = (shadowModelView * vec4(fragment_position_feet, 1.0)).xyz;
        vec3 fragment_normal_shadow_view = mat3(shadowModelView) * fragment_normal_world;

        // Project and distort for texture sampling
        vec4 fragment_shadow_clip = shadowProjection * vec4(fragment_position_shadow_view, 1.0);
        vec3 fragment_shadow_clip_warped = distort_shadow_clip_position(fragment_shadow_clip.xyz);
        vec2 fragment_shadow_uv = fragment_shadow_clip_warped.xy * 0.5 + 0.5;

        vec3 irradiance = vec3(0.0);
        for (int i = 0; i < RSM_SAMPLE_COUNT; i += 1) {
            float r = RSM_SAMPLE_RADIUS * sqrt(float(i + 1) / float(RSM_SAMPLE_COUNT));
            float theta = fract(float(i) / float(RSM_SAMPLE_COUNT)) * 2.0 * PI;
            vec2 offset = r * vec2(sin(theta), cos(theta));

            vec2 sample_uv = fragment_shadow_uv + offset;

            // Read sample depth and reconstruct position
            float sample_depth = texture(shadowtex1, sample_uv).r;
            vec3 sample_shadow_screen_warped = vec3(sample_uv * 2.0 - 1.0, sample_depth);
            vec3 sample_shadow_view = project_and_divide(shadowProjectionInverse, sample_shadow_screen_warped);

            // Read sample data
            vec4 sample_color = texture(shadowcolor0, sample_uv);
            vec3 sample_flux = rgb_to_linear(sample_color.rgb * sample_color.a);
            vec3 sample_normal = texture(shadowcolor1, sample_uv).xyz * 2.0 - 1.0;

            vec3 direction = normalize(fragment_position_shadow_view - sample_shadow_view);

            irradiance += sample_flux *
                    max0(dot(direction, sample_normal)) *
                    max0(dot(-direction, fragment_normal_shadow_view)) *
                    rcp(pow2(distance(sample_shadow_view, fragment_position_shadow_view)));
        }

        irradiance /= float(RSM_SAMPLE_COUNT);
        irradiance *= PI * RSM_SAMPLE_RADIUS * RSM_BRIGHTNESS;

        return irradiance;
    }
#endif
