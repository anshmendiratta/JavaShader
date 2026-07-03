#if !defined INCLUDE_SKY_COLOR
    #define INCLUDE_SKY_COLOR

    #include "/include/settings.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/utility/phase_functions.glsl"

    #define MAGIC_FOG_VALUE 0.08 // taken from shrimple v2: https://github.com/Null-MC/Shrimple/blob/f4fcab627cc62bd2e66813c58cd657bb4ecbb84f/shaders/lib/fog/fog_common.glsl#L1

    float _fogify(float x, float w) {
        return w / (x * x + w);
    }

    // returns in linear space
    vec3 get_sky_color(vec3 sky_color, vec3 fog_color, float up_factor) {
        vec3 fogcolor_oklab = rgb_to_oklab(fog_color);
        vec3 skycolor_oklab = rgb_to_oklab(sky_color);

        float fogified_factor = _fogify(up_factor, MAGIC_FOG_VALUE);
        vec3 oklab_mixed = mix(skycolor_oklab, fogcolor_oklab, fogified_factor);
        vec3 rgb_mixed = oklab_to_rgb(oklab_mixed);

        return rgb_mixed;
    }

    // PBR SKY WORK.

    const float SCALE_HEIGHT = 0.25;
    const float ATMOSPHERE_HEIGHT = 100.0;

    const float G_RAYLEIGH = 0.0;
    const float G_MIE = 0.8;

    const uint SCATTERING_SAMPLES = 6;

    vec3 out_scattering(in vec3 scattering_sample_view_space) {
        vec3 scattering_sample_world_space = view_to_world(scattering_sample_view_space);
        return vec3(4.0 * PI * ATMOSPHERE_HEIGHT * (exp(-scattering_sample_world_space.y / ATMOSPHERE_HEIGHT) - exp(-1))); // last term is the integral if the sun is incident on the sky dome.
    }

    vec3 in_scattering(in vec3 scattering_sample_view_space) {
        vec3 scattering_sample_world_space = view_to_world(scattering_sample_view_space);
        vec3 sunlight_intensity = vec3(1.0);
        float scattering_constant = 1.0; // assume.
        float cos_theta = cos(2.0 * PI * sunAngle);
        float phase_rayleigh = _phase_modified_henyey_greenstein(cos_theta, G_RAYLEIGH);
        float phase_mie = _phase_modified_henyey_greenstein(cos_theta, G_MIE);

        return sunlight_intensity * scattering_constant * (phase_rayleigh + phase_mie);
    }

    const vec3 RAYLEIGH_SCATTERING_VECTOR = vec3(
    RAYLEIGH_SCATTER_R,
    RAYLEIGH_SCATTER_G,
    RAYLEIGH_SCATTER_B
    );

    vec3 get_pbr_sky_color(in vec3 fragment_position_view_space) {
        fragment_position_view_space = normalize(fragment_position_view_space); // unit distance from camera
        vec3 fragment_position_world_space = view_to_world(fragment_position_view_space);
        vec3 light_position_world_space = view_to_world(shadowLightPosition);

        vec3 v = mat3(gbufferModelViewInverse) * normalize(fragment_position_view_space); // vector
        vec3 s_hat = normalize(fragment_position_world_space - light_position_world_space);

        float cos_theta = dot(-s_hat, v);

        float phase_r = _phase_rayleigh(cos_theta);
        float phase_m = _phase_mie(0.85, cos_theta);

        vec3 sigma_sum = S_R * RAYLEIGH_SCATTERING_VECTOR + S_M;
        vec3 phase_sum = S_R * phase_r * RAYLEIGH_SCATTERING_VECTOR + S_M * phase_m;

        return LIGHT_INTENSITY * (s_hat.y * rcp(s_hat.y + v.y)) * (phase_sum * rcp(sigma_sum)) *
            (exp(sigma_sum * rcp(s_hat.y)) - exp(-sigma_sum * rcp(v.y)));
    }
#endif
