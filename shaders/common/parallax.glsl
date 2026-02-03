// REQUIRES:
// - POM_HEIGHT_SCALE (/lib/settings.glsl)
// - `normals` texture.

#include "/common/math.glsl"

#define get_height_at_uv(uv) 1.0 - textureGrad(normals, uv, uv_gradient[0], uv_gradient[1]).a

vec2 pom_uv_transform(vec2 uv, /* camera to fragment */ vec3 view_direction_tangent_space, mat2 uv_gradient) {
    int layers_count = int(mix(POM_MIN_LAYERS, POM_MAX_LAYERS, abs(dot(vec3(0.0, 0.0, 1.0), view_direction_tangent_space)))); // Dot with vec3(0.0, 0.0, 1.0) as we want more layers as the view is steeper.
    float layer_height_interval = rcp(float(layers_count));

    vec2 ray = view_direction_tangent_space.xz * rcp(view_direction_tangent_space.y) * POM_HEIGHT_SCALE * layer_height_interval; // Final vector we use as our initial approximation.
    vec2 d_uv = ray * layer_height_interval / ray.y;

    // Linear search for last two UVs.
    float current_ray_sample_height = 1.0;
    float current_displacement_height = get_height_at_uv(uv);

    while (current_ray_sample_height > 0.0) {
        if (current_displacement_height >= current_ray_sample_height) break;
        current_ray_sample_height -= layer_height_interval; // Go down one layer.
        // Resample.
        uv += d_uv;
        current_displacement_height = get_height_at_uv(uv);
    }

    // Found first UV above intersection (I think?). Calculate previous UV for weighting.
    float previous_displacement_height = get_height_at_uv(uv - d_uv);
    float current_displacment_sample_height_delta = abs(current_displacement_height - current_ray_sample_height);
    float previous_displacment_sample_height_delta = abs(previous_displacement_height - (current_ray_sample_height - layer_height_interval));
    float uv_weight = current_displacment_sample_height_delta / (current_displacment_sample_height_delta + previous_displacment_sample_height_delta);
    vec2 final_uv = uv - (1.0 - uv_weight) * d_uv;

    return final_uv;
}

vec2 local_uv_to_atlas(vec2 local_uv, vec2 bottom_left_coord, vec2 texture_size) {
    return fract(local_uv) * texture_size + bottom_left_coord;
}

vec2 atlas_uv_to_local(vec2 atlas_uv, vec2 bottom_left_coord, vec2 texture_size) {
    return (atlas_uv - bottom_left_coord) / texture_size;
}
