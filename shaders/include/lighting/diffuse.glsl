#if !defined INCLUDE_DIFFUSE
    #define INCLUDE_DIFFUSE

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"

    vec3 _diffuse_lambertian(Material material, vec3 light_source_vector_world);
    vec3 _diffuse_silly_lambertian(Material material, vec3 light_source_vector_world);
    vec3 _diffuse_oren_nayar(Material material, vec3 light_source_vector_world);
    vec3 _diffuse_burley(Material material, vec3 light_source_vector_world, vec3 frag_view_vector_world);

    vec3 compute_diffuse(Material material, in vec3 vertex_normal, in vec3 light_source_vector_world, in vec3 frag_view_vector_world) {
        return _diffuse_burley(material, light_source_vector_world, frag_view_vector_world);
        // return _diffuse_lambertian(material, light_source_vector_world);
        // return _diffuse_oren_nayar(material, light_source_vector_world);
    }

    // -----------------------
    //     Diffuse models
    // -----------------------
    // of the below models, N.L is technically the only "correct" one, but the others look nice

    vec3 _diffuse_lambertian(Material material, vec3 light_source_vector_world) {
        float lambertian = clamp01(dot(light_source_vector_world, material.normal));

        return vec3(lambertian / PI);
    }

    // https://lisyarus.github.io/blog/posts/a-silly-diffuse-shading-model.html
    vec3 _diffuse_silly_lambertian(Material material, vec3 light_source_vector_world) {
        float silly_lambertian = pow2(0.5 + 0.5 * dot(light_source_vector_world, material.normal));

        return vec3(silly_lambertian / PI);
    }

    vec3 _diffuse_burley(Material material, in vec3 light_source_vector_world, in vec3 frag_view_vector_world) {
        vec3 halfway_vector_world = normalize(light_source_vector_world + frag_view_vector_world);
        float l_dot_h = dot(light_source_vector_world, halfway_vector_world);
        float n_dot_v = dot(material.normal, frag_view_vector_world) + 1e-5;
        float n_dot_l = dot(material.normal, light_source_vector_world);

        float f90 = 0.5 + 2. * material.roughness * pow2(l_dot_h);
        vec3 light_scatter = vec3(_fresnel_schlick_burley(n_dot_l, 1., f90));
        vec3 view_scatter = vec3(_fresnel_schlick_burley(n_dot_v, 1., f90));

        return light_scatter * view_scatter / PI;
    }
#endif
