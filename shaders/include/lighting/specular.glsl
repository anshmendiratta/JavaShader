#if !defined INCLUDE_SPECULAR
    #define INCLUDE_SPECULAR

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/hcm.glsl"

    float _ggx_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _ggx_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _beckmann_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);

    // uses cook-tarrance: https://en.wikipedia.org/wiki/Specular_highlight#Cook%E2%80%93Torrance_model
    vec3 compute_specular(const in Material material, const in vec3 light_source_vector_world, const in vec3 view_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);

        float first_attenuation_term = 2.0 * rcp(dot(view_vector_world, halfway_vector_world)) * dot(halfway_vector_world, material.normal) * dot(view_vector_world, material.normal); // 2(H.N)(V.N)/V.H
        float second_attenuation_term = 2.0 * rcp(dot(view_vector_world, halfway_vector_world)) * dot(halfway_vector_world, material.normal) * dot(light_source_vector_world, material.normal); // 2(H.N)(L.N)/V.H
        float geometric_attenuation = _ggx_g(material, view_vector_world, light_source_vector_world); // g
        // FIX: for some reason, the bottom two don't give reasonable results anymore
        // float geometric_attenuation = min1(min(first_attenuation_term, second_attenuation_term)); // g
        // float intensity_distribution = _beckmann_d(material, view_vector_world, light_source_vector_world); // d
        float intensity_distribution = _ggx_d(material, view_vector_world, light_source_vector_world); // d

        vec3 specular_highlight = rcp(PI) * material.fresnel * intensity_distribution * geometric_attenuation;
        if (material.is_metal) {
            specular_highlight *= material.albedo;
        }

        return specular_highlight;
    }

    // ------------------------------
    //     Distribution functions
    // ------------------------------

    // ggx and beckmann from: https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
    // - alpha_b = roughness
    // - theta_m = angle between H, N
    // - m = halfway (i think)
    // - n = normal

    // function tags:
    // - g = geometric attenuation
    // - d = distribution

    float _ggx_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float view_angle = acos(dot(material.normal, view_vector_world));

        return char_positive(dot(halfway_vector_world, view_vector_world) / dot(halfway_vector_world, material.normal)) * 2.0 * rcp(1.0 + sqrt(1 + pow2(material.roughness) * pow2(tan(view_angle))));
    }

    float _ggx_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float incident_angle = acos(dot(material.normal, halfway_vector_world));

        return char_positive(dot(material.normal, halfway_vector_world)) * pow2(material.roughness) * rcp(PI * pow4(cos(incident_angle)) * pow2(pow2(material.roughness) + pow2(tan(incident_angle))));
    }

    // https://en.wikipedia.org/wiki/Specular_highlight#Beckmann_distribution
    float _beckmann_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float cos_alpha = dot(halfway_vector_world, material.normal);
        float tan_alpha = rcp(pow2(cos_alpha)) - 1; // tan^2 = sec^2 - 1

        return char_positive(dot(material.normal, halfway_vector_world)) * exp(-pow2(tan_alpha) * rcp(material.roughness)) * rcp(PI * pow2(material.roughness) * pow4(cos_alpha));
    }
#endif
