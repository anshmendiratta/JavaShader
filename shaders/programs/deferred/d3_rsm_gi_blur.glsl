#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 3 */
    layout(location = 0) out vec3 rsm_gi_blurred;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/depth_conversion.glsl"

    #define RSM_BLUR_SAMPLES 16
    #define DEPTH_SENSITIVITY 500.0
    #define RSM_BLUR_RADIUS 10.0

    // TODO: there has to be a better blur than this

    void main() {
        vec2 texel_size = 1.0 / textureSize(colortex2, 0);

        // Get center depth for edge-aware filtering
        float center_depth = texture(depthtex2, uv).r;

        // Early exit for sky
        if (center_depth == 1.0) {
            rsm_gi_blurred = vec3(0.0);
            return;
        }

        float center_z = depth_to_z(center_depth);
        vec3 center_rsm_gi = texture(colortex2, uv).rgb;

        float total_weight = 1.0;
        vec3 weighted_sum = center_rsm_gi;

        // Bilateral blur with edge-aware filtering
        float dither = compute_dither(gl_FragCoord.xy);
        for (int idx = 0; idx < RSM_BLUR_SAMPLES; idx += 1) {
            vec2 offset_uv = compute_vogel_disk_sample_uv(idx, RSM_BLUR_SAMPLES);
            vec2 sample_offset = RSM_BLUR_RADIUS * texel_size * offset_uv;
            vec2 sample_uv = uv + sample_offset;

            // Sample RSM GI and depth
            vec3 sample_rsm_gi = texture(colortex2, sample_uv).rgb;
            float sample_depth = texture(depthtex2, sample_uv).r;

            // Skip sky samples
            if (sample_depth == 1.0) continue;

            float sample_z = depth_to_z(sample_depth);

            // Depth-aware weight: preserve geometry edges
            float depth_diff = abs(center_z - sample_z);
            float depth_weight = exp(-depth_diff * depth_diff * DEPTH_SENSITIVITY);

            // Spatial weight: Gaussian falloff
            float radius_factor = dot(offset_uv, offset_uv);
            float spatial_weight = exp(-1.0 * radius_factor);

            float weight = depth_weight * spatial_weight;
            weighted_sum += sample_rsm_gi * weight;
            total_weight += weight;
        }

        rsm_gi_blurred = weighted_sum / total_weight;
    }
#endif
