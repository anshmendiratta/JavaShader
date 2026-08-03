#if !defined INCLUDE_WATER_WAVES
    #define INCLUDE_WATER_WAVES

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/utility/dither.glsl"

    #include "/include/math/convenience.glsl"
    #include "/include/math/arcane.glsl"

    #define GRAVITY 9.81f

    #define WAVE_COMPONENTS 16u

    vec3 k_m[WAVE_COMPONENTS]; // wavenumbers
    float a_m[WAVE_COMPONENTS]; // amplitudes
    float phi_m[WAVE_COMPONENTS]; // phase offsets
    float omega_m[WAVE_COMPONENTS]; // angular velocities
    float theta_m[WAVE_COMPONENTS];

    // ------------------
    //     Prototypes
    // ------------------

    void _populate_gerstner_parameters(in vec3 frag_position_world, in uint component);
    float _compute_theta_m(float alpha, float beta, float t, uint component);

    // ----------------------
    //     Gerstner waves
    // ----------------------
    // from:
    // - https://en.wikipedia.org/wiki/Trochoidal_wave,
    // - http://www-evasion.imag.fr/Membres/Fabrice.Neyret/NaturalScenes/fluids/water/waves/fluids-nuages/waves/Jonathan/articlesCG/simulating-ocean-water-01.pdf
    //
    // assumes a mean water depth of 1.

    vec3 _compute_water_displacement(vec3 frag_position_world) {
        float y = 0.;

        for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
            _populate_gerstner_parameters(frag_position_world, component);
            y += a_m[component] * cos(theta_m[component]);
        }

        return vec3(0., y, 0.);
    }

    // NOTE: returns world space
    vec3 compute_water_normal(in vec3 frag_position_world) {
        float dh_dx = 0.;
        float dh_dz = 0.;

        for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
            _populate_gerstner_parameters(frag_position_world, component);
            float frequency = 2e-1 * pow(0.6, component);
            dh_dx += -k_m[component].x * a_m[component] * sin(frequency * theta_m[component]);
            dh_dz += -k_m[component].z * a_m[component] * sin(frequency * theta_m[component]);
        }

        return normalize(vec3(-dh_dx, 1., -dh_dz));
    }

    // -----------------
    //     Auxiliary
    // -----------------

    float _compute_theta_m(float alpha, float beta, float t, uint component) {
        return dot(vec2(alpha, beta), k_m[component].xz) - omega_m[component] * t - phi_m[component];
    }

    void _populate_gerstner_parameters(in vec3 frag_position_world, in uint component) {
        float alpha = frag_position_world.x;
        float beta = frag_position_world.z;
        float t = frameTimeCounter * 10.;

        float theta_i = radians(15.) * float(component);
        float lambda_i = 3e-1 * pow(1.6, -float(component));
        k_m[component] = 2. * PI / lambda_i * vec3(cos(theta_i), 0., sin(theta_i));

        a_m[component] = WATER_WAVE_AMPLITUDE * pow(0.8, component);
        phi_m[component] = sqrt(2. * PI * rcp(float(component + 1)));
        omega_m[component] = sqrt(GRAVITY * length(k_m[component]) * tanh(length(k_m[component]) * /* calculate for 1m below sea level*/ 1.0));
        theta_m[component] = _compute_theta_m(alpha, beta, t, component);
    }
#endif
