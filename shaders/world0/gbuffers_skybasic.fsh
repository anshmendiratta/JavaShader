#version 330 compatibility

// TODO: Understand why the sky coloring works how it does.

uniform sampler2D colortex0;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 shadowLightPosition;
uniform float viewHeight;
uniform float viewWidth;

in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/constants.glsl"
#include "/lib/utility.glsl"

const float EPSILON = 1e-6;
const float FAR_DISTANCE = 1e20;
const float EARTH_RADIUS = 6371000.0;
const vec3 EARTH_ORIGIN = vec3(0.0, -EARTH_RADIUS, 0.0);
const float ATMO_THICKNESS = 100000.0;
const float RAYLEIGH_SCALE = (ATMO_THICKNESS * 0.08);
const float MIE_SCALE = (ATMO_THICKNESS * 0.012);
const float PI = 3.14159265359;

const float rayleigh_coeff = 1.0;
const float mie_coeff = 1.0;
const float ozone_coeff = 1.0;
const vec3 BETA_RAYLEIGH = vec3(5.802, 13.558, 33.100) * 1e-6;
const vec3 BETA_MIE = vec3(3.996, 3.996, 3.996) * 1e-6;
const vec3 BETA_OZONE = vec3(0.650, 1.881, 0.085) * 1e-6;

const float atmo_density_scale = 1.0;
const float light_exposure = 10.0;
const float solar_disc_softness = 0.1;
const float solar_brightness = 10.0;

const bool apply_aces = true;

vec3 aces_tonemap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec2 intersect_sphere(vec3 origin, vec3 direction, vec3 center, float radius) {
    origin -= center;
    float term_a = dot(direction, direction);
    float term_b = 2.0 * dot(origin, direction);
    float term_c = dot(origin, origin) - (radius * radius);
    float discriminant = term_b * term_b - 4.0 * term_a * term_c;
    if (discriminant < 0.0) {
        return vec2(-1.0);
    } else {
        discriminant = sqrt(discriminant);
        return vec2(-term_b - discriminant, -term_b + discriminant) / (2.0 * term_a);
    }
}

vec2 intersect_atmo_shell(vec3 origin, vec3 direction) {
    return intersect_sphere(origin, direction, EARTH_ORIGIN, EARTH_RADIUS + ATMO_THICKNESS);
}

float scattering_phase_rayleigh(float mu) {
    return 3.0 * (1.0 + mu * mu) / (16.0 * PI);
}

float scattering_phase_mie(float mu, float g_factor) {
    g_factor = min(g_factor, 0.9381);
    float k_param = 1.55 * g_factor - 0.55 * g_factor * g_factor * g_factor;
    float k_mu = k_param * mu;
    return (1.0 - k_param * k_param) / ((4.0 * PI) * (1.0 - k_mu) * (1.0 - k_mu));
}

float get_altitude(vec3 world_pos) {
    return distance(world_pos, EARTH_ORIGIN) - EARTH_RADIUS;
}

float compute_rayleigh_density(float altitude) {
    return exp(-max(0.0, altitude / RAYLEIGH_SCALE));
}

float compute_mie_density(float altitude) {
    return exp(-max(0.0, altitude / MIE_SCALE));
}

float compute_ozone_density(float altitude) {
    return max(0.0, 1.0 - abs(altitude - 25000.0) / 15000.0);
}

vec3 compute_densities(float altitude) {
    return vec3(compute_rayleigh_density(altitude), compute_mie_density(altitude), compute_ozone_density(altitude));
}

vec3 calculate_optical_depth(vec3 origin, vec3 direction) {
    vec2 bounds = intersect_atmo_shell(origin, direction);
    float march_distance = bounds.y;
    int num_steps = 4;
    float step_length = march_distance / float(num_steps);
    vec3 depth_accumulator = vec3(0.0);

    for (int i = 0; i < num_steps; i++) {
        vec3 sample_pos = origin + direction * (float(i) + 0.5) * step_length;
        float sample_altitude = get_altitude(sample_pos);
        vec3 sample_density = compute_densities(sample_altitude);
        depth_accumulator += sample_density * step_length;
    }

    return depth_accumulator;
}

vec3 compute_extinction(vec3 depth) {
    return exp(-(
        depth.x * BETA_RAYLEIGH * rayleigh_coeff +
            depth.y * BETA_MIE * mie_coeff * 1.1 +
            depth.z * BETA_OZONE * ozone_coeff
        ) * atmo_density_scale);
}

vec3 march_scattering(vec3 origin, vec3 direction, float march_dist, vec3 light_dir, vec3 light_tint, out vec3 total_transmit) {
    float view_altitude = get_altitude(origin);
    float step_distribution = 1.0 + clamp(1.0 - view_altitude / ATMO_THICKNESS, 0.0, 1.0) * 8.0;

    vec2 bounds = intersect_atmo_shell(origin, direction);
    march_dist = min(march_dist, bounds.y);
    if (bounds.x > 0.0) {
        origin += direction * bounds.x;
        march_dist -= bounds.x;
    }

    float phase_angle = dot(direction, light_dir);
    float rayleigh_phase = scattering_phase_rayleigh(phase_angle);
    float mie_phase = scattering_phase_mie(phase_angle, 0.85);

    int num_steps = 32;

    vec3 depth_accumulator = vec3(0.0);
    vec3 rayleigh_scatter = vec3(0.0);
    vec3 mie_scatter = vec3(0.0);

    float last_t = 0.0;

    for (int i = 0; i < num_steps; i++) {
        float current_t = pow(float(i) / float(num_steps), step_distribution) * march_dist;
        float delta_t = (current_t - last_t);

        vec3 sample_pos = origin + direction * current_t;
        float sample_altitude = get_altitude(sample_pos);
        vec3 sample_density = compute_densities(sample_altitude);

        depth_accumulator += sample_density * delta_t;

        vec3 view_extinction = compute_extinction(depth_accumulator);

        vec3 light_depth = calculate_optical_depth(sample_pos, light_dir);
        vec3 light_extinction = compute_extinction(light_depth);

        rayleigh_scatter += view_extinction * light_extinction * rayleigh_phase * sample_density.x * delta_t;
        mie_scatter += view_extinction * light_extinction * mie_phase * sample_density.y * delta_t;

        last_t = current_t;
    }

    total_transmit = compute_extinction(depth_accumulator);

    return (rayleigh_scatter * BETA_RAYLEIGH * rayleigh_coeff + mie_scatter * BETA_MIE * mie_coeff) * light_tint * light_exposure;
}

float render_sun_disc(vec3 view_dir, vec3 sun_dir, float angular_size) {
    float angle_dot = dot(view_dir, sun_dir);
    float inner_edge = cos(angular_size * (1.0 - solar_disc_softness));
    float outer_edge = cos(angular_size * (1.0 + solar_disc_softness));
    return smoothstep(outer_edge, inner_edge, angle_dot);
}

vec3 calc_sky_color(vec3 fragment_feet_space_position) {
    vec3 shadow_light_direction = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float up_dot = clamp(dot(fragment_feet_space_position, shadow_light_direction), 0.0, 1.0);
    return mix(skyColor, fogColor, up_dot);
}

void main() {
    vec3 final_color;
    if (starData.a > 0.5) {
        final_color = starData.rgb;
    } else {
        vec3 fragment_screen_space_position = vec3(texcoord.xy, 1.0);
        vec3 fragment_ndc_space_position = fragment_screen_space_position * 2.0 - 1.0;
        vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
        vec3 fragment_feet_space_position = mat3(gbufferModelViewInverse) * fragment_view_space_position;
        final_color = calc_sky_color(fragment_feet_space_position);

        // vec2 uv = fragment_screen_space_position.xy;
        // vec3 rayDir = normalize(vec3(uv.x, uv.y + 0.8, 1.0));

        // vec2 sunUV = project_and_divide(gbufferProjection, shadowLightPosition).xy * 0.5 + 0.5;
        // vec3 sunDir = normalize(vec3(sunUV.x, sunUV.y + 0.8, 1.0));

        // vec3 total_transmit;
        // vec3 scattered_light = march_scattering(vec3(0.0), rayDir, FAR_DISTANCE, sunDir, vec3(1.0, 0.996, 0.98), total_transmit);

        // float solar_mask = render_sun_disc(rayDir, sunDir, 0.02);
        // vec3 solar_contribution = vec3(solar_mask) * total_transmit * solar_brightness;

        // vec3 final_color = scattered_light + solar_contribution;

        // if (apply_aces) {
        //     final_color = aces_tonemap(final_color);
        // }
    }

    color = vec4(final_color, 1.0);
    // color = vec4(1.0); //gcolor
    // color = vec4(pow(final_color, vec3(2.2)), 1.0); //gcolor
}
