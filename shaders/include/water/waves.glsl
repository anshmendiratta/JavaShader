#if !defined INCLUDE_WATER_WAVES
    #define INCLUDE_WATER_WAVES

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    // gerstner waves from https://en.wikipedia.org/wiki/Trochoidal_wave
    // free variables: amplitude_m, k_m, phi_m with m \in [1, WAVE_COMPONENTS]

    #define WAVE_COMPONENTS 10
    #define MEAN_WATER_DEPTH 0.0
    #define GRAVITY 9.81

    float phi_m[WAVE_COMPONENTS];
    float omega_m[WAVE_COMPONENTS];
    float theta_m[WAVE_COMPONENTS];

    const float _k_mx = 3.0;
    const float _k_mz = 5.0;
    const vec3 k_m = vec3(_k_mx, 0.0, _k_mz); // NOTE: x/z need to be different

    float _compute_y();
    float _compute_theta_m(float alpha, float beta, float t, uint component);

    vec3 compute_water_displacement(vec3 frag_position_world) {
        float alpha = frag_position_world.x;
        float beta = frag_position_world.z;
        float t = frameTimeCounter * 1e-2;

        // populate phi, omega, and theta tables
        for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
            phi_m[component] = sqrt(2.0 * PI * rcp(float(component + 1)));
            omega_m[component] = sqrt(GRAVITY * length(k_m)); // tanh(k_m h) = 0.0. if we include it, waves are static
            theta_m[component] = _compute_theta_m(alpha, beta, t, component);
        }

        vec3 water_displacement = vec3(
                0.0,
                _compute_y(),
                0.0
            );

        return WATER_WAVE_AMPLITUDE * water_displacement;
    }

    // TODO: naive, expensive way. use derivatives to find approximations of nearby points.
    // NOTE: returns world space
    vec3 compute_water_normal(vec3 frag_position_world, vec3 frag_water_displacement) {
        vec3 dx_frag = frag_position_world + vec3(EPSILON, 0.0, 0.0);
        vec3 dz_frag = frag_position_world + vec3(0.0, 0.0, EPSILON);
        vec3 dx = compute_water_displacement(dx_frag) + vec3(EPSILON, 0.0, 0.0);
        vec3 dz = compute_water_displacement(dz_frag) + vec3(0.0, 0.0, EPSILON);
        // names not accurate

        return normalize(cross(dz, dx)); // NOTE: unsure about order
    }

    float _compute_y() {
        float sum = 0.0;
        for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
            float component_amplitude = pow2(rcp(float(component + 1)));

            sum += component_amplitude * cos(theta_m[component]);
        }

        return sum;
    }

    float _compute_theta_m(float alpha, float beta, float t, uint component) {
        return k_m.x * alpha + k_m.z * beta - omega_m[component] * t * 100. - phi_m[component];
    }

#endif
