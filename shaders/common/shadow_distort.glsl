#include "/lib/settings.glsl"

const float SHADOW_BIAS_STARTER = SHADOW_BIAS;
const float SHADOW_BIAS_EPSILON = 0.1;

vec3 distort_shadow_clip_space_position(vec3 position) {
    float distortion_factor = length(position.xy) + SHADOW_BIAS_EPSILON; // Shadow clip space (xy) is the light source looking at the player (so they are the origin (0, 0)). Since there is no perspective in clip space, the distance from the player of the point (x', y') is the same in all directions, making this method work. Some bugs arise when the distances are tiny, so we increment this a bit too.
    position.xy /= distortion_factor; // Apply distortion.
    position.z *= 0.5; // The origin (x, y, z) = (0, 0, 0) in clip space is the light source, so we don't apply the distortion if the arrow digs into or comes out of the screen. Instead, this value lets you control how far the shadows can stretch -- the default is 256 blocks, so halving this value lets you fit 512 blocks worth of shadow.

    return position;
}

float compute_shadow_bias(vec3 position) {
    float distortion_factor = length(position.xy) + SHADOW_BIAS_EPSILON;

    return SHADOW_BIAS_STARTER / SHADOW_MAP_RESOLUTION * (distortion_factor * distortion_factor) / SHADOW_BIAS_EPSILON; // 1.0 / shadowMapResolution * square(length(position.xy) + EPSILON) / EPSILON
}
