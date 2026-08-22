#if !defined INCLUDE_SPECULAR
    #define INCLUDE_SPECULAR

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/hcm.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    float _ggx_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _ggx_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _ggx_v(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _kelemen_v(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _beckmann_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
    float _beckmann_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);

    // ----------------
    //     Specular
    // ----------------
    // uses cook-tarrance:
    // - https://en.wikipedia.org/wiki/Specular_highlight#Cook%E2%80%93Torrance_model
    // - https://graphicscompendium.com/theory/07-cook-torrance
    // FIX: there is a weird shimmer that can appear across blocks at very specific angles. this is time-of-day sensitive and independent of D/G

    vec3 compute_specular(const in Material material, const in vec3 fresnel, const in vec3 light_source_vector_world, const in vec3 view_vector_world) {
        float d = _ggx_d(material, view_vector_world, light_source_vector_world);
        float v = _kelemen_v(material, view_vector_world, light_source_vector_world);
        // float v = _ggx_v(material, view_vector_world, light_source_vector_world);
        vec3 f = fresnel;

        vec3 specular_highlight = f * d * v;

        if (material.is_metal) {
            specular_highlight *= material.albedo;
        }

        return max0(specular_highlight);
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

    float _kelemen_v(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float l_dot_h = clamp01(dot(light_source_vector_world, halfway_vector_world));

        return 0.25 / pow2(l_dot_h);
    }

    float _ggx_v(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        float n_dot_l = clamp01(dot(material.normal, light_source_vector_world));
        float n_dot_v = clamp01(dot(material.normal, view_vector_world)) + 1e-5;

        float a = pow2(material.roughness);
        float ggx_l = n_dot_v * sqrt(pow2(n_dot_l) * (1. - a) + a);
        float ggx_v = n_dot_l * sqrt(pow2(n_dot_v) * (1. - a) + a);

        return 0.5 / (ggx_l + ggx_v);
    }

    float _ggx_d_x(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world, in const vec3 x) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float cos_view_angle = dot(material.normal, x);
        float tan_sqr_view_angle = (1.0 - pow2(cos_view_angle)) * rcp(pow2(cos_view_angle));

        return char_positive(dot(halfway_vector_world, x) / dot(x, material.normal)) * 2.0 * rcp(1.0 + sqrt(1.0 + pow2(material.roughness) * tan_sqr_view_angle));
    }

    float _ggx_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        float ggx_g_v = _ggx_d_x(material, view_vector_world, light_source_vector_world, view_vector_world);
        float ggx_g_l = _ggx_d_x(material, view_vector_world, light_source_vector_world, light_source_vector_world);

        return ggx_g_l * ggx_g_v;
    }

    // from: https://graphicscompendium.com/theory/08-cook-torrance-ggx
    float _ggx_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float n_dot_h = clamp01(dot(material.normal, halfway_vector_world));

        float a = pow2(material.roughness);
        float f = (n_dot_h * a - n_dot_h) * n_dot_h + 1.;

        return a / (PI * pow2(f));
    }

    // https://en.wikipedia.org/wiki/Specular_highlight#Beckmann_distribution
    float _beckmann_d(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float cos_alpha = dot(halfway_vector_world, material.normal);
        float tan_sqr_alpha = (1.0 - pow2(cos_alpha)) * rcp(pow2(cos_alpha));

        return char_positive(cos_alpha) * exp(-tan_sqr_alpha * rcp(pow2(material.roughness))) * rcp(PI * pow2(material.roughness) * pow4(cos_alpha));
    }

    // from above paper. also an approximation to the original attenuation function because of the erf
    float _beckmann_g(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
        vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);
        float cos_theta_v = dot(material.normal, halfway_vector_world);
        float tan_theta_v = sqrt((1.0 - pow2(cos_theta_v)) * rcp(pow2(cos_theta_v)));
        float a = rcp(material.roughness * tan_theta_v);

        if (a >= 1.6) return char_positive(dot(view_vector_world, halfway_vector_world) / dot(view_vector_world, material.normal));

        return char_positive(dot(view_vector_world, halfway_vector_world) * rcp(dot(view_vector_world, material.normal))) * (3.535 * a + 2.181 * pow2(a)) * rcp(1 + 2.276 * a + 2.577 * pow2(a));
    }
#endif
