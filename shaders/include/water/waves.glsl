#if !defined INCLUDE_WATER_WAVES
#define INCLUDE_WATER_WAVES

#include "/include/settings.glsl"
#include "/include/uniforms.glsl"

// #include "/include/utility/dither.glsl"

#include "/include/math/convenience.glsl"

// gerstner waves from https://en.wikipedia.org/wiki/Trochoidal_wave
// free variables: amplitude_m, k_m, phi_m with m \in [1, WAVE_COMPONENTS]

#define WAVE_COMPONENTS 10
#define MEAN_WATER_DEPTH 0.0
#define GRAVITY 9.81

vec3 k_m[WAVE_COMPONENTS];
float phi_m[WAVE_COMPONENTS];
float omega_m[WAVE_COMPONENTS];
float theta_m[WAVE_COMPONENTS];

// const float _k_mx = 3.0;
// const float _k_mz = 5.0;
// const vec3 k_m = vec3(_k_mx, 0.0, _k_mz); // NOTE: x/z need to be different

float _compute_y();
float _compute_theta_m(float alpha, float beta, float t, uint component);

vec3 compute_water_displacement(vec3 frag_position_world) {
    float alpha = frag_position_world.x;
    float beta = frag_position_world.z;
    float t = frameTimeCounter * 1e-2;

    // float dither = compute_dither(uv);
    float dither = 1.;

    // populate phi, omega, and theta tables
    for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
        float wave_number = 2 + component * 0.5;
        float angle_offset = dither * wave_number;
        float current_angle = TAU + angle_offset;
        k_m[component] = wave_number * vec3(cos(current_angle), 0., sin(current_angle));

        phi_m[component] = sqrt(2.0 * PI * rcp(float(component + 1)));
        omega_m[component] = sqrt(GRAVITY * length(k_m[component])); // tanh(k_m h) = 0.0. if we include it, waves are static
        theta_m[component] = _compute_theta_m(alpha, beta, t, component);
    }

    vec3 water_displacement = vec3(
            0.0,
            _compute_y(),
            0.0
        );

    return WATER_WAVE_AMPLITUDE * water_displacement;
}

float _compute_dy_dtheta(uint component) {
    // Mirror the exact amplitude calculation used in _compute_y()
    float component_amplitude = pow2(rcp(float(component + 1)));

    float theta = theta_m[component];

    // d/dtheta (amplitude * cos(theta)) = -amplitude * sin(theta)
    return -component_amplitude * sin(theta);
}

// NOTE: returns world space
vec3 compute_water_normal(vec3 frag_position_world, vec3 frag_water_displacement) {
    float alpha = frag_position_world.x;
    float beta = frag_position_world.z;
    float t = frameTimeCounter * 1e-2;

    float dy_dalpha = 0.0;
    float dy_dbeta = 0.0;

    // 1. Re-populate tables and accumulate partial derivatives
    for (uint component = 0; component < WAVE_COMPONENTS; component += 1) {
        phi_m[component] = sqrt(2.0 * PI * rcp(float(component + 1)));
        omega_m[component] = sqrt(GRAVITY * length(k_m[component]));
        theta_m[component] = _compute_theta_m(alpha, beta, t, component);

        // Chain Rule: dY/dAlpha = dY/dTheta * dTheta/dAlpha
        // (where dTheta/dAlpha is just k_m.x)
        float dy_dtheta = _compute_dy_dtheta(component);

        dy_dalpha += dy_dtheta * k_m[component].x * WATER_WAVE_AMPLITUDE;
        dy_dbeta += dy_dtheta * k_m[component].z * WATER_WAVE_AMPLITUDE;
    }

    // 2. Cross product of tangents simplified: vec3(-dy_dalpha, 1.0, -dy_dbeta)
    vec3 normal = vec3(-dy_dalpha, 1.0, -dy_dbeta);

    return normalize(normal);
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
    return k_m[component].x * alpha + k_m[component].z * beta - omega_m[component] * t * 100. - phi_m[component];
}
#endif
