#if !defined INCLUDE_MATERIAL
    #define INCLUDE_MATERIAL

    #include "/include/uniforms.glsl"

    #include "/include/utility/bits.glsl"

    #include "/include/pbr/hcm.glsl"
    #include "/include/pbr/textures.glsl"

    struct Material {
        // fragment information
        vec3 albedo;
        // vectors
        vec3 normal; // world space
        // PBR info
        float ao;
        float depth;
        float roughness;
        vec3 f0; // reflectance.
        float porosity;
        float sss; // subsurface scattering
        float emissiveness;

        // flags. some taken from photon
        bool is_metal; // default: false
        uint metal_id;

        // general
        uint block_id;
        vec2 lightmap_uv;
    };

    void init_material_unpacked_colortex_read(out Material material) {
        vec4 normal_map_read, specular_map_read;
        vec2 lightmap_uv;
        uint block_id;
        unpack_colortex1_read(texture(colortex1, uv), normal_map_read, specular_map_read, lightmap_uv, block_id);

        material.albedo = texture(gtexture, uv).rgb;
        material.block_id = block_id;
        material.lightmap_uv = lightmap_uv;

        vec2 octahedral_encoded_normal = normal_map_read.xy * 2.0 - 1.0;
        vec3 normal_world_space = vector_decode_octahedral(octahedral_encoded_normal);
        material.normal = vec3(normal_world_space);

        material.ao = normal_map_read.b;
        material.depth = normal_map_read.a;

        material.roughness = pow2(1.0 - specular_map_read.r);
        material.porosity = (specular_map_read.b <= 64.0 / 255.0) ? (specular_map_read.b / 64.0) : 0.0;
        material.sss = (specular_map_read.b >= 65.0 / 255.0) ? (specular_map_read.b - 65.0 / 255.0) : 0.0;
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
