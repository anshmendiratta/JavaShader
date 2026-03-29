#if !defined INCLUDE_SPECULAR
    #define INCLUDE_SPECULAR

    #include "/include/utility/math_fp.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/hcm.glsl"

    vec3 _fresnel_phong(Material material, vec3 view_vector_world_space, vec3 light_source_direction_vector_world_space);
    vec3 _fresnel_schlick(Material material, vec3 light_source_direction_vector_world_space);
    vec3 _fresnel_rescaled_schlick(Material material, vec3 light_source_direction_vector_world_space);

    vec3 compute_specular(Material material, vec3 light_source_direction_world_space, float n_dot_l) {
        vec3 fresnel;
        // TODO: find a fresnel func that isnt metal/dielectric specific
        if (material.is_metal) {
            fresnel = _fresnel_rescaled_schlick(material, -light_source_direction_world_space); // TODO: why does the second arg need negating...?
        } else {
            fresnel = _fresnel_schlick(material, -light_source_direction_world_space);
        }

        return fresnel * material.albedo;
    }

    // all of the below are approximations of reflectance (the amount of reflected light) and is calculated exactly using fresnel's equations

    vec3 _fresnel_phong(Material material, vec3 view_vector_world_space, vec3 light_source_direction_vector_world_space) {
        vec3 halfway_vector_world_space = normalize(light_source_direction_vector_world_space + view_vector_world_space);

        return vec3(clamp01(dot(material.normal, halfway_vector_world_space)));
    }

    vec3 _fresnel_schlick(Material material, vec3 light_source_direction_vector_world_space) {
        float cosine_incident_ray_angle = clamp01(dot(material.normal, light_source_direction_vector_world_space));

        return material.f0 + (vec3(1.0) - material.f0) * pow5(1.0 - cosine_incident_ray_angle);
    }

    // https://naos-be.zcu.cz/server/api/core/bitstreams/c2d8b0a7-9947-4458-98e3-d3f8df920153/content
    vec3 _fresnel_rescaled_schlick(Material material, vec3 light_source_direction_vector_world_space) {
        float cosine_incident_ray_angle = clamp01(dot(material.normal, light_source_direction_vector_world_space));

        vec3 n = hcm_ior[material.metal_id];
        vec3 k = hcm_ext[material.metal_id];

        vec3 numerator = pow3(n - 1) + 4 * n * pow5(1 - cosine_incident_ray_angle) + pow2(k);
        vec3 denominator = pow2(n + 1) + pow2(k);

        return numerator / denominator;
    }
#endif
