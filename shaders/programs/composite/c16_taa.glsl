#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/post/taa.glsl"

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0,20,22 */

    layout(location = 0) out vec4 color;
    layout(location = 1) out vec4 history;
    layout(location = 2) out float depth_history;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/buffers.glsl"

    #include "/include/post/taa.glsl"

    #include "/include/color/conversions.glsl"

    vec4 weigh_luminance(in vec3 hdr);

    void main() {
        vec2 uv = uv - dot(
                    vec2(dFdx(uv).x, dFdy(uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);

        vec4 current_frame = texture(colortex0, uv);
        vec3 reproj_uv = reproject_uv(uv);
        vec4 previous_frame = texture(BUFFER_TAA, reproj_uv.xy);

        vec4 current_weight = weigh_luminance(current_frame.rgb);
        // current_frame.rgb = current_weight.rgb;
        vec4 previous_weight = weigh_luminance(previous_frame.rgb);
        // previous_frame.rgb = previous_weight.rgb;

        // color clamping: create a bounding box to clamp the reproj color into

        vec3 min_color = vec3(-1e3);
        vec3 max_color = vec3(1e3);

        for (float x = -1; x < 1; x += 1) {
            for (float y = -1; y < 1; y += 1) {
                vec2 sample_uv = uv + vec2(x, y) / windowDimensions;
                vec3 sample_color = texture(colortex0, sample_uv).rgb;

                // luminance weighting
                // sample_color = weigh_luminance(sample_color).rgb;

                min_color = min(min_color, current_frame.rgb);
                max_color = max(max_color, current_frame.rgb);
            }
        }

        previous_frame.rgb = clamp(min_color, max_color, previous_frame.rgb);

        float taa_blend = 0.875;

        float depth = texture(depthtex0, uv).x;
        if (abs(depth - reproj_uv.z) > 1e-3) taa_blend = 0.; // depth rejection
        taa_blend /= mix(1., 8., tanh(10. * distance(previousCameraPosition, cameraPosition))); // bad motion vector substitute

        color = mix(current_frame, previous_frame, taa_blend);
        // color /= mix(current_weight.a, previous_weight.a, taa_blend);

        history = color;
        depth_history = texture(depthtex0, uv).x;
    }

    vec4 weigh_luminance(in vec3 hdr) {
        float luminance = rgb_to_luminance(linear_to_rgb(hdr));
        float luminance_weight = luminance / (1. + luminance);
        return luminance_weight * vec4(hdr, 1.);
    }
#endif
