#if !defined INCLUDE_MATERIAL
    #define INCLUDE_MATERIAL

    #include "/include/uniforms.glsl"

    #include "/include/utility/bits.glsl"

    #include "/include/pbr/hcm.glsl"

    struct Material {
        // fragment information
        vec3 albedo;
        // vectors.
        vec3 normal; // world space
        // PBR info.
        float ao;
        float depth;
        float roughness;
        vec3 f0; // reflectance.
        float specular_b; // porosity/sss.
        float emissiveness;

        // flags. some taken from photon
        bool is_metal; // default: false
        uint metal_id;
    };

    void init_material_raw_read(out Material material, vec2 uv) {
        material.albedo = texture(gtexture, uv).rgb;

        // normal map
        vec4 normal_data = texture(normals, uv);
        normal_data.xy = normal_data.xy * 2.0 - 1.0;
        material.normal = vec3(normal_data.xy, sqrt(1.0 - dot(normal_data.xy, normal_data.xy)));
        material.ao = normal_data.b;
        material.depth = normal_data.a;

        // specular map
        vec4 specular_data = texture(specular, uv);
        material.roughness = pow2(1.0 - specular_data.r);
        material.specular_b = specular_data.b;
        material.emissiveness = fract(specular_data.a); // since 0 and 255 are no emission

        // handle hcm
        material.is_metal = (specular_data.g >= 230.0 / 255.0);
        if (material.is_metal) {
            const uint metal_id = clamp(uint(255.0 * specular_data.g) - 230, 0, 7); // TODO: treats all metal ids >= 238 and <= 250 as 237. change to accomodate for id 255 as well
            material.f0 = compute_hcm_f0(metal_id);
            material.metal_id = metal_id;
        } else {
            material.f0 = vec3(specular_data.g);
            material.metal_id = 0;
        }
    }

    // Likely to be called after a `decode_colortex1`.
    void init_material_unpacked_colortex_read(out Material material, vec4 normal_map_read, vec4 specular_map_read, vec2 uv) {
        material.albedo = texture(gtexture, uv).rgb;

        vec2 octahedral_encoded_normal = normal_map_read.xy * 2.0 - 1.0;
        vec3 normal_world_space = vector_decode_octahedral(octahedral_encoded_normal);
        material.normal = vec3(normal_world_space);

        material.ao = normal_map_read.b;
        material.depth = normal_map_read.a;

        material.roughness = pow2(1.0 - specular_map_read.r);
        material.specular_b = specular_map_read.b;
        material.emissiveness = fract(specular_map_read.a);

        material.is_metal = (specular_map_read.g >= 230.0 / 255.0);
        if (material.is_metal) {
            // treat everything as a vanilla metal. even modded ones
            const uint metal_id = clamp(uint(255.0 * specular_map_read.g) - 230, 0, 7);
            material.f0 = compute_hcm_f0(metal_id);
            material.metal_id = metal_id;
        } else {
            material.f0 = vec3(specular_map_read.g);
            material.metal_id = 0;
        }
    }
#endif
