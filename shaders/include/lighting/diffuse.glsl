#if !defined INCLUDE_DIFFUSE
    #define INCLUDE_DIFFUSE

    #include "/include/math/convenience.glsl"

    vec3 _diffuse_lambertian(Material material, vec3 light_source_vector_world);
    vec3 _diffuse_silly_lambertian(Material material, vec3 light_source_vector_world);
    vec3 _diffuse_oren_nayar(Material material, vec3 light_source_vector_world);

    vec3 compute_diffuse(Material material, vec3 light_source_vector_world) {
        // return _diffuse_silly_lambertian(material, light_source_vector_world);
        return _diffuse_lambertian(material, light_source_vector_world);
        // return _diffuse_oren_nayar(material, light_source_vector_world);
    }

    // of the below models, N.L is technically the only "correct" one, but the others look nice

    vec3 _diffuse_lambertian(Material material, vec3 light_source_vector_world) {
        float lambertian = clamp01(dot(light_source_vector_world, material.normal));

        return vec3(lambertian);
    }

    // https://lisyarus.github.io/blog/posts/a-silly-diffuse-shading-model.html
    vec3 _diffuse_silly_lambertian(Material material, vec3 light_source_vector_world) {
        float silly_lambertian = pow2((1.0 + dot(light_source_vector_world, material.normal)) / 2.0);

        return vec3(silly_lambertian);
    }

    // FIX: broken. all black
    // https://en.wikipedia.org/wiki/Oren%E2%80%93Nayar_reflectance_model#Formulation
    vec3 _diffuse_oren_nayar(Material material, vec3 light_source_vector_world) {
        vec3 rho = material.albedo;
        vec3 E_0 = vec3(1.0);
        float sigma_squared = material.roughness; // NOTE: probably wrong
        float phi_i = acos(dot(light_source_vector_world, material.normal));
        float phi_r = phi_i;
        float theta_i = 0.0;
        float theta_r = 0.0;

        float alpha = max(theta_i, theta_r);
        float beta = max(phi_i, phi_r);
        float C_1 = 1 - rcp(2.0) * sigma_squared / (sigma_squared + 0.33);
        float C_2 = 0.45 * sin(alpha) * sigma_squared / (sigma_squared + 0.09); // since cos(phi_i - phi_r) = cos(0) = 1 >= 0
        float C_3 = 0.125 * sigma_squared / (sigma_squared + 0.09) * pow2(4 * alpha * beta * rcp(pow2(PI)));

        vec3 L_1 = rho * rcp(PI) * E_0 * cos(theta_i) * (C_1 + C_2 * cos(phi_i - phi_r) * tan(beta) + C_3 * (1 - abs(cos(phi_i - phi_r)) * tan(rcp(2.0) * (alpha + beta))));
        vec3 L_2 = 0.17 * pow2(rho) * rcp(PI) * E_0 * cos(theta_i) * sigma_squared / (sigma_squared + 0.13) * (1 - cos(phi_i - phi_r) * pow2(2.0 * beta * rcp(PI)));

        return L_1 + L_2;
    }

#endif
