#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 2 */

    layout(location = 0) out vec3 rsm_gi_blurred;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/utility/depth_conversion.glsl"

    #define ATROUS_STEP_WIDTH 5.0
    #define DEPTH_PHI 300.0
    #define NORMAL_PHI 32.0
    #define GI_PHI 8.0

    float luminance(vec3 v) {
        return dot(v, vec3(0.2126, 0.7152, 0.0722));
    }

    void main() {
        vec2 texel_size = 1.0 / vec2(textureSize(colortex2, 0));
        float center_depth = texture(depthtex2, uv).r;

        if (center_depth >= 1.0) {
            rsm_gi_blurred = vec3(0.0);
            return;
        }

        float center_z = depth_to_z(center_depth);
        vec3 center_rsm_gi = texture(colortex2, uv).rgb;
        vec3 center_normal = normalize(texture(colortex3, uv).xyz * 2.0 - 1.0);
        float center_luma = luminance(center_rsm_gi);

        const float atrous_kernel[3] = float[3](0.375, 0.25, 0.0625);

        float total_weight = 0.0;
        vec3 weighted_sum = vec3(0.0);

        for (int y = -2; y <= 2; y += 1) {
            for (int x = -2; x <= 2; x += 1) {
                vec2 offset = vec2(float(x), float(y)) * texel_size * ATROUS_STEP_WIDTH;
                vec2 sample_uv = clamp(uv + offset, vec2(0.0), vec2(1.0));

                vec3 sample_rsm_gi = texture(colortex2, sample_uv).rgb;
                vec3 sample_normal = normalize(texture(colortex3, sample_uv).xyz * 2.0 - 1.0);
                float sample_luma = luminance(sample_rsm_gi);
                float sample_depth = texture(depthtex2, sample_uv).r;

                if (sample_depth >= 1.0) continue;

                float sample_z = depth_to_z(sample_depth);

                float spatial_weight = atrous_kernel[abs(x)] * atrous_kernel[abs(y)];
                float depth_weight = exp(-abs(center_z - sample_z) * DEPTH_PHI);
                float normal_weight = pow(max(dot(center_normal, sample_normal), 0.0), NORMAL_PHI);
                float gi_weight = exp(-abs(center_luma - sample_luma) * GI_PHI);

                float weight = spatial_weight * depth_weight * normal_weight * gi_weight;

                weighted_sum += sample_rsm_gi * weight;
                total_weight += weight;
            }
        }

        rsm_gi_blurred = total_weight > 0.0 ? weighted_sum / total_weight : center_rsm_gi;
    }
#endif
