// hcm = hardcoded metals (per the labpbr spec where tha values are taken from).

#if !defined INCLUDE_HCM
    #define INCLUDE_HCM

    #include "/include/math/convenience.glsl"

    // n, ior = index of refraction
    const vec3 hcm_ior[8] = {
            vec3(2.91140, 2.94970, 2.58450), // iron
            vec3(0.18299, 0.42108, 1.37340), // gold
            vec3(1.34560, 0.96521, 0.61722), // aluminum
            vec3(3.10710, 3.18120, 2.32300), // chrome
            vec3(0.27105, 0.67693, 1.31640), // copper
            vec3(1.91000, 1.83000, 1.44000), // lead
            vec3(2.37570, 2.08470, 1.84530), // platinum
            vec3(0.15943, 0.14512, 0.13547) // silver
    };
    // k, ext = extinction coefficient
    const vec3 hcm_ext[8] = {
            vec3(3.0893, 2.9318, 2.7670), // iron
            vec3(3.4242, 2.3459, 1.7704), // gold
            vec3(7.4746, 6.3995, 5.3031), // aluminum
            vec3(3.3314, 3.3291, 3.1350), // chrome
            vec3(3.6092, 2.6248, 2.2921), // copper
            vec3(3.5100, 3.4000, 3.1800), // lead
            vec3(4.2655, 3.7153, 3.1365), // platinum
            vec3(3.9291, 3.1900, 2.3808) // silver
    };

    // assumes the incident ray always comes from air. hence, n_i = 1.0
    vec3 compute_hcm_f0(uint metal_id) {
        vec3 n = hcm_ior[metal_id];
        vec3 k = hcm_ext[metal_id];

        // https://seblagarde.wordpress.com/2013/04/29/memo-on-fresnel-equations/
        // R(0) = Re ((n_t + ik_t) - n_i)((n_t - ik_t) - n_1) / (((n_t + ik_t) + n_i)((n_t - ik_t) + n_i))

        vec3 numerator_real = (n - vec3(1.0)) * (n - vec3(1.0));
        vec3 numerator_imag = k * k;
        vec3 denominator_real = (n + vec3(1.0)) * (n + vec3(1.0));
        vec3 denominator_imag = k * k;

        vec3 result_real = rcp(pow2(denominator_real) + pow2(denominator_imag)) * (numerator_real * denominator_real + numerator_imag * denominator_imag);

        return rcp(pow2(denominator_real) + pow2(denominator_imag)) * result_real;
    }
#endif
