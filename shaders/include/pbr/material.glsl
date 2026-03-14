#if !defined INCLUDE_MATERIAL
    #define INCLUDE_MATERIAL

    #include "/include/uniforms.glsl"

    #include "/include/utility/bits.glsl"

    struct Material {
        // Vectors.
        vec3 normal; // world space
        // PBR info.
        float ao;
        float depth;
        float nonlinear_smoothness; // Convert to linear with pow(1.0 - smoothness, 2.0).
        float f0; // Reflectance.
        float specular_b; // Porosity/SSS.
        float emissiveness;
    };

    void init_material_raw_read(out Material material, vec2 uv) {
        #if NORMAL_MAPPING == 1
            vec4 normal_data = texture(normals, uv);
            normal_data.xy = normal_data.xy * 2.0 - 1.0;
            material.normal = vec3(normal_data.xy, sqrt(1.0 - dot(normal_data.xy, normal_data.xy)));
            material.ao = normal_data.b;
            material.depth = normal_data.a;
        #endif
        #if SPECULAR_MAPPING == 1
            vec4 specular_data = texture(specular, uv);
            material.nonlinear_smoothness = specular_data.r;
            material.f0 = specular_data.g;
            material.specular_b = specular_data.b;
            material.emissiveness = specular_data.a;
        #endif
    }

    // Likely to be called after a `decode_colortex1`.
    void init_material_unpacked_colortex_read(out Material material, vec4 normal_map_read, vec4 specular_map_read) {
        #if NORMAL_MAPPING == 1
            vec2 octahedral_encoded_normal = normal_map_read.xy;
            vec3 normal_world_space = vector_decode_octahedral(octahedral_encoded_normal);
            material.normal = vec3(normal_world_space);

            material.ao = normal_map_read.b;
            material.depth = normal_map_read.a;
        #else
            vec2 octahedral_encoded_normal = normal_map_read.xy;
            vec3 normal_world_space = vector_decode_octahedral(octahedral_encoded_normal);
            material.normal = vec3(normal_world_space);
        #endif
        #if SPECULAR_MAPPING == 1
            material.nonlinear_smoothness = specular_map_read.r;
            material.f0 = specular_map_read.g;
            material.specular_b = specular_map_read.b;
            material.emissiveness = specular_map_read.a;
        #endif
    }
#endif
