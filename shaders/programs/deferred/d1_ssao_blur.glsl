#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 4 */
    layout(location = 0) out float ssao_factor;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/math/convenience.glsl"
    #include "/include/utility/random.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/depth_conversion.glsl"

    #define SSAO_BLUR_SAMPLES 64
    #define DEPTH_SENSITIVITY 300.0 // Higher = sharper edges

    void main() {
        vec2 texel_size = 1.0 / textureSize(colortex4, 0);

        // Get center depth for edge-aware filtering
        float center_depth = texture(depthtex2, uv).r;

        if (frag_is_hand(center_depth)) return;

        // Early exit for sky
        if (center_depth == 1.0) {
            ssao_factor = 1.0;
            return;
        }

        float center_z = depth_to_z(center_depth);
        float center_ssao = texture(colortex4, uv).r;

        float total_weight = 1.0;
        float weighted_sum = center_ssao;

        // Very aggressive bilateral blur to completely eliminate noise
        for (int idx = 0; idx < SSAO_BLUR_SAMPLES; idx += 1) {
            vec2 offset_uv = compute_vogel_disk_sample_uv(idx, SSAO_BLUR_SAMPLES);
            vec2 sample_offset = SSAO_BLUR_RADIUS * texel_size * offset_uv;
            vec2 sample_uv = uv + sample_offset;

            // Sample SSAO and depth
            float sample_ssao = texture(colortex4, sample_uv).r;
            float sample_depth = texture(depthtex2, sample_uv).r;

            // Skip sky/cloud samples
            if (sample_depth == 1.0) continue;

            float sample_z = depth_to_z(sample_depth);

            // Depth-aware weight: extremely strong edge preservation
            float depth_diff = abs(center_z - sample_z);
            float depth_weight = exp(-depth_diff * depth_diff * DEPTH_SENSITIVITY);

            // Spatial weight: very soft Gaussian falloff for maximum coverage
            float radius_factor = dot(offset_uv, offset_uv);
            float spatial_weight = exp(-1.0 * radius_factor);

            float weight = depth_weight * spatial_weight;
            weighted_sum += sample_ssao * weight;
            total_weight += weight;
        }

        ssao_factor = weighted_sum / total_weight;
    }
#endif
