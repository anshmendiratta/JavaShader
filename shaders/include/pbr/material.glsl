#if !defined INCLUDE_MATERIAL
    #define INCLUDE_MATERIAL

    #include "/include/ids.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/utility/bits.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/pbr/hcm.glsl"
    #include "/include/pbr/textures.glsl"

    struct Material {
        // pbr
        float ao;
        float depth;
        float roughness;
        float porosity;
        float sss; // subsurface scattering
        float emissiveness;
        vec3 albedo;
        vec3 normal; // world space
        vec3 f0; // reflectance.
        vec3 fresnel;

        // flags. some taken from photon
        bool is_metal; // default: false

        // general
        uint block_id;
        uint metal_id;
        vec2 lightmap_uv;
    };

    vec3 _fresnel_phong(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    vec3 _fresnel_schlick(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    vec3 _fresnel_rescaled_schlick(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);

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
        material.porosity = specular_data.b <= 64.0 / 255.0 ? (specular_data.b / 64.0) : 0.0;
        material.sss = specular_data.b >= 65.0 / 255.0 ? (specular_data.b - 65.0) / 255.0 : 0.0;
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

    void init_material_unpacked_colortex_read(out Material material) {
        uint block_id;
        vec2 lightmap_uv;
        vec4 normal_map_read, specular_map_read;
        unpack_colortex1_read(texture(colortex1, uv), normal_map_read, specular_map_read, lightmap_uv, block_id);

        material.albedo = texture(gtexture, uv).rgb;
        material.block_id = block_id;
        material.lightmap_uv = lightmap_uv;

        vec2 octahedral_encoded_normal = normal_map_read.xy * 2.0 - 1.0;
        vec3 normal_world = vector_decode_octahedral(octahedral_encoded_normal);
        material.normal = vec3(normal_world);

        material.ao = normal_map_read.b;
        material.depth = normal_map_read.a;
        material.roughness = pow2(1.0 - specular_map_read.r);
        material.porosity = (specular_map_read.b <= 64.0 / 255.0) ? (specular_map_read.b * 255.0 * rcp(64.0)) : 0.0;
        material.sss = (specular_map_read.b >= 65.0 / 255.0) ? (specular_map_read.b - 65.0 * rcp(255.0)) : 0.0;
        material.emissiveness = fract(specular_map_read.a);

        material.is_metal = (specular_map_read.g >= 230.0 / 255.0);
        if (material.is_metal) {
            // treat everything as a vanilla metal. even modded ones
            const uint metal_id = clamp(uint(255.0 * specular_map_read.g) - 230, 0, 7);
            material.f0 = compute_hcm_f0(metal_id);
            material.metal_id = metal_id;
        } else {
            material.f0 = (material.block_id == ID_WATER) ?
                vec3(0.04) : // value from axolotan
                vec3(specular_map_read.g);
            material.metal_id = 0;
        }

        // fresnel
        vec3 fragment_ndc_position = vec3(uv, texture(depthtex0, uv).r) * 2.0 - 1.0;
        vec3 fragment_view_position = ndc_to_view(fragment_ndc_position);
        vec3 fragment_feet_position = view_to_feet(fragment_view_position);
        vec3 fragment_world_position = feet_to_world(fragment_feet_position);
        vec3 light_source_world_position = feet_to_world(view_to_feet(shadowLightPosition));
        vec3 light_source_vector_world = normalize(light_source_world_position - fragment_world_position);
        vec3 view_vector_world = normalize(fragment_world_position - cameraPosition);

        material.fresnel = material.is_metal ?
            clamp01(_fresnel_rescaled_schlick(material, view_vector_world, light_source_vector_world)) :
            clamp01(_fresnel_schlick(material, view_vector_world, light_source_vector_world));
    }

    // ------------------------------
    //     Fresnel approximations
    // ------------------------------

    // all of the below are approximations of reflectance (the amount of reflected light) where `fresnel` is calculated _exactly_ using fresnel's equations

    vec3 _fresnel_phong(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);

        return vec3(clamp01(dot(material.normal, halfway_vector_world)));
    }

    vec3 _fresnel_schlick(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float h_dot_v = clamp01(dot(halfway_vector_world, view_vector_world));

        return material.f0 + (1.0 - material.f0) * pow5(1.0 - h_dot_v);
    }

    // https://naos-be.zcu.cz/server/api/core/bitstreams/c2d8b0a7-9947-4458-98e3-d3f8df920153/content
    vec3 _fresnel_rescaled_schlick(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float h_dot_v = clamp01(dot(halfway_vector_world, view_vector_world));

        vec3 n = hcm_ior[material.metal_id];
        vec3 k = hcm_ext[material.metal_id];

        vec3 numerator = pow3(n - 1) + 4 * n * pow5(1 - h_dot_v) + pow2(k);
        vec3 denominator = pow2(n + 1) + pow2(k);

        return numerator / denominator;
    }
#endif
