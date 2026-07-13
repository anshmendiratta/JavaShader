#if !defined INCLUDE_PHASE_FUNCTIONS
    #define INCLUDE_PHASE_FUNCTIONS

    #include "/include/math/convenience.glsl"

    float _phase_henyey_greenstein(float cos_theta, float anisotropy_factor);
    float _phase_isotropic();
    float _phase_rayleigh(float cos_theta);
    float _phase_mie(float anisotropy_factor, float cos_theta);

    // most real materials have g \in [0.77, 0.9]
    float _phase_henyey_greenstein(float cos_theta, float anisotropy_factor) {
        float g = anisotropy_factor;
        return rcp(4.0 * PI) * (1 - pow2(g)) / pow(1 + pow2(g) - 2 * g * cos_theta, 1.5);
    }

    float _phase_isotropic() {
        return rcp(4.0 * PI);
    }

    // from: https://rhept.org/posts/scattering/

    float _phase_rayleigh(float cos_theta) {
        return 3. * rcp(16. * PI) * (1. + pow2(cos_theta));
    }

    float _phase_mie(float anisotropy_factor, float cos_theta) {
        const float C = 0.5;
        return C * pow2(anisotropy_factor * rcp(1. + anisotropy_factor - cos_theta));
    }

    // from: https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering
    //
    // "For Mie aerosol scattering, g is usually set between -0.75 and -0.999"
    float _phase_modified_henyey_greenstein(float cos_theta, float anisotropy_factor) {
        float g = anisotropy_factor;
        return 3.0 / 2.0 * (1 - pow2(g)) / (2 + pow2(g)) * (1 + pow2(cos_theta)) / pow(1 + pow2(g) - 2 * g * cos_theta, 1.5);
    }
#endif