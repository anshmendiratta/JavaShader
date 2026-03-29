#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    // TODO: fix noise coming through in ssao. dither maybe?

    in vec2 uv;

    /* RENDERTARGETS: 4 */
    layout(location = 0) out float occlusion_factor;

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/dither.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    vec3 ssao_sampling_kernel[SSAO_SAMPLE_COUNT]; // Vectors in tangent space.
    vec3 ssao_noise_vector; // Create less than 1 per fragment to save memory. Use this as a tiling "texture."

    void main() {
        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;

        // skip for the sky
        float fragment_depth = texture(depthtex2, uv).r;
        if (fragment_depth == 1.0) {
            occlusion_factor = 1.0 - 0.0;
            return;
        }

        // Sampling kernel of random vector offsets.
        for (int count = 0; count < SSAO_SAMPLE_COUNT; count += 1) {
            float scale = float(count) / float(SSAO_SAMPLE_COUNT);
            scale = smoothstep01(scale * scale); // Quadratic density.
            float dither = compute_dither(count * uv);
            float epsilon_zero = sample_default_noise(screen_uv + vec2(dither) / screen_uv).r;
            float epsilon_one = sample_default_noise(windowDimensions - screen_uv + vec2(dither) / screen_uv).r;
            float phi = 2.0 * PI * epsilon_one;
            float theta = acos(sqrt(epsilon_zero));
            ssao_sampling_kernel[count] = scale * vec3(
                        cos(phi) * sin(theta),
                        sin(phi) * sin(theta),
                        abs(cos(theta))
                    );
        }

        // Random rotation vector.
        float dither = compute_dither(uv);
        int count = int(4.0 * rand(uv.x + uv.y));
        float epsilon_zero = sample_default_noise(screen_uv + vec2(dither) / screen_uv).r;
        float epsilon_one = sample_default_noise(windowDimensions - screen_uv + vec2(dither) / screen_uv).r;
        float phi = 2.0 * PI * epsilon_one;
        float theta = acos(sqrt(epsilon_zero));
        ssao_noise_vector = vec3(
                sin(phi) * cos(theta),
                sin(phi) * sin(theta),
                cos(theta)
            );

        // unpack colortex1
        vec4 normal_map_read, specular_map_read;
        vec2 lightmap_uv, o_uv;
        unpack_colortex1_read(texture(colortex1, uv), normal_map_read, specular_map_read, lightmap_uv, o_uv);
        Material material;
        init_material_unpacked_colortex_read(material, normal_map_read, specular_map_read, uv);

        // Construct TBN.
        vec3 fragment_screen_space_position = vec3(uv, texture(depthtex2, uv).r);
        vec3 fragment_ndc_space_position = fragment_screen_space_position * 2.0 - 1.0;
        vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
        vec3 normal_world_space = material.normal;
        vec3 normal_view_space = normalize(mat3(gbufferModelView) * normal_world_space);
        vec3 random_vector = ssao_noise_vector;
        vec3 tangent_view_space = normalize(random_vector - normal_view_space * dot(normal_view_space, random_vector));
        vec3 bitangent_view_space = normalize(cross(tangent_view_space, normal_view_space));
        mat3 TBN_matrix = mat3(tangent_view_space, bitangent_view_space, normal_view_space); // Tangent space to view space.

        // Obtain depth samples for occlusion check.
        float fragment_z = depth_to_z(fragment_depth);
        occlusion_factor = 0.0;
        for (int idx = 0; idx < SSAO_SAMPLE_COUNT; idx += 1) {
            vec3 sample_offset_view_space = TBN_matrix * ssao_sampling_kernel[idx];
            vec3 sample_view_space_position = fragment_view_space_position + sample_offset_view_space;
            float sample_z = sample_view_space_position.z;

            vec3 sample_screen_space_position = project_and_divide(gbufferProjection, sample_view_space_position) * 0.5 + 0.5;
            float sample_object_depth = texture(depthtex2, sample_screen_space_position.xy).r;
            vec3 sample_object_ndc_position = vec3(sample_screen_space_position.xy, sample_object_depth) * 2.0 - 1.0;
            vec3 sample_object_view_space_position = project_and_divide(gbufferProjectionInverse, sample_object_ndc_position);
            float sample_object_z = sample_object_view_space_position.z;

            float is_occluded = sample_z <= sample_object_z + SSAO_BIAS ? 1.0 : 0.0;
            float within_z_range = smoothstep01(rcp(5.0) * SSAO_RADIUS / abs(fragment_view_space_position.z - sample_object_z));
            occlusion_factor += is_occluded * within_z_range;
        }

        occlusion_factor /= float(SSAO_SAMPLE_COUNT);
        occlusion_factor = pow(smoothstep01(1.0 - occlusion_factor), AMBIENT_INTENSITY);
    }
#endif
