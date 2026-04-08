#if !defined INCLUDE_PHASE_FUNCTIONS
    #define INCLUDE_PHASE_FUNCTIONS

    #include "/include/math/convenience.glsl"

    float _phase_henyey_greenstein(float cos_theta, float anisotropy_factor);
    float _phase_isotropic();

    // most real materials have g \in [0.77, 0.9]
    float _phase_henyey_greenstein(float cos_theta, float anisotropy_factor) {
        float g = anisotropy_factor;

        return rcp(4.0 * PI) * (1 - pow2(g)) / (1 + pow2(g) + 2 * g * pow(cos_theta, 1.5));
    }

    float _phase_isotropic() {
        return rcp(4.0 * PI);
    }
#endif
