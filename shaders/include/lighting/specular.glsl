#if !defined INCLUDE_SPECULAR
    #define INCLUDE_SPECULAR

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/hcm.glsl"

    vec3 _fresnel_phong(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space);
    vec3 _fresnel_schlick(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space);
    vec3 _fresnel_rescaled_schlick(Material material, vec3 light_source_vector_world_space);

    float _distribution_ggx();
    float _distribution_beckmann(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space);

    // uses cook-tarrance: https://en.wikipedia.org/wiki/Specular_highlight#Cook%E2%80%93Torrance_model
    vec3 compute_specular(Material material, vec3 light_source_vector_world_space, vec3 view_vector_world_space, out vec3 fresnel) {
        vec3 halfway_vector_world_space = normalize(view_vector_world_space + light_source_vector_world_space);

        // TODO: find a fresnel func that isnt metal/dielectric specific
        if (material.is_metal) {
            fresnel = clamp01(_fresnel_rescaled_schlick(material, light_source_vector_world_space));
        } else {
            fresnel = clamp01(_fresnel_schlick(material, view_vector_world_space, light_source_vector_world_space));
        }

        float first_attenuation_term = 2.0 * rcp(dot(view_vector_world_space, halfway_vector_world_space)) * dot(halfway_vector_world_space, material.normal) * dot(view_vector_world_space, material.normal); // 2(H.N)(V.N)/V.H
        float second_attenuation_term = 2.0 * rcp(dot(view_vector_world_space, halfway_vector_world_space)) * dot(halfway_vector_world_space, material.normal) * dot(light_source_vector_world_space, material.normal); // 2(H.N)(L.N)/V.H
        float geometric_attenuation = min1(min(first_attenuation_term, second_attenuation_term)); // g
        float intensity_distribution = _distribution_beckmann(material, view_vector_world_space, light_source_vector_world_space); // d

        vec3 specular_highlight = fresnel / PI * intensity_distribution * geometric_attenuation;
        if (material.is_metal) {
            specular_highlight *= material.albedo;
        }

        return specular_highlight;
    }

    // all of the below are approximations of reflectance (the amount of reflected light) where `fresnel` is calculated _exactly_ using fresnel's equations

    vec3 _fresnel_phong(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space) {
        vec3 halfway_vector_world_space = normalize(view_vector_world_space + light_source_vector_world_space);

        return vec3(clamp01(dot(material.normal, halfway_vector_world_space)));
    }

    vec3 _fresnel_schlick(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space) {
        vec3 halfway_vector_world_space = normalize(view_vector_world_space + light_source_vector_world_space);
        float cosine_incident_ray_angle = clamp01(dot(material.normal, halfway_vector_world_space));

        return material.f0 + (1.0 - material.f0) * pow5(1.0 - cosine_incident_ray_angle);
    }

    // https://naos-be.zcu.cz/server/api/core/bitstreams/c2d8b0a7-9947-4458-98e3-d3f8df920153/content
    vec3 _fresnel_rescaled_schlick(Material material, vec3 light_source_vector_world_space) {
        float cosine_incident_ray_angle = clamp01(dot(material.normal, light_source_vector_world_space));

        vec3 n = hcm_ior[material.metal_id];
        vec3 k = hcm_ext[material.metal_id];

        vec3 numerator = pow3(n - 1) + 4 * n * pow5(1 - cosine_incident_ray_angle) + pow2(k);
        vec3 denominator = pow2(n + 1) + pow2(k);

        return numerator / denominator;
    }

    // -----------------------------
    //     Distribution functios
    // -----------------------------

    // TODO: impl
    float _distribution_ggx() {
        return 0.;
    }

    // https://en.wikipedia.org/wiki/Specular_highlight#Beckmann_distribution
    float _distribution_beckmann(Material material, vec3 view_vector_world_space, vec3 light_source_vector_world_space) {
        vec3 halfway_vector_world_space = normalize(view_vector_world_space + light_source_vector_world_space);
        float alpha = acos(dot(halfway_vector_world_space, material.normal));

        return exp(-pow2(tan(alpha)) * rcp(material.roughness)) / (PI * material.roughness * pow4(cos(alpha)));
    }

#endif
