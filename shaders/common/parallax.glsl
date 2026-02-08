// REQUIRES:
// - POM_HEIGHT_SCALE (/lib/settings.glsl)
// - `normals` texture.

#include "/common/math.glsl"

vec2 local_uv_to_atlas(vec2 local_uv, vec2 bottom_left_coord, vec2 texture_size) {
    return fract(local_uv) * texture_size + bottom_left_coord;
}

vec2 atlas_uv_to_local(vec2 atlas_uv, vec2 bottom_left_coord, vec2 texture_size) {
    return (atlas_uv - bottom_left_coord) * rcp(texture_size);
}

float sample_heightmap(vec2 uv, mat2 uv_gradient) {
    // Requires atlas space coordinates for sampling.
    vec2 atlas_uv = local_uv_to_atlas(uv, texture_bottom_left, single_tex_size);
    return 1.0 - textureGrad(normals, atlas_uv, uv_gradient[0], uv_gradient[1]).a;
}

vec2 pom_uv_transform(in vec2 local_uv, /* camera to fragment */ vec3 view_direction_tangent_space, mat2 uv_gradient) {
    // int layers_count = int(mix(POM_MIN_LAYERS, POM_MAX_LAYERS, abs(view_direction_tangent_space.y)));
    int layers_count = POM_MAX_LAYERS;
    float layer_height_interval = rcp(float(layers_count));

    vec2 ray_direction = view_direction_tangent_space.xy * rcp(view_direction_tangent_space.z); // Final vector we use as our initial approximation.
    vec2 d_uv = ray_direction * layer_height_interval * POM_HEIGHT_SCALE;

    // Linear search for last two UVs.
    float current_ray_sample_height = 1.0;
    float current_displacement_height = sample_heightmap(local_uv, uv_gradient);
    // Snippet from https://github.com/sixthsurge/photon/blob/40adec318ea608d9f9ba88fcc272730af0899a62/shaders/include/surface/parallax.glsl#L32.
    if (current_displacement_height < rcp(255.0)) {
        return local_uv;
    }

    local_uv += d_uv;
    // Advance while the sampling ray is above the heightmap value (i.e. we haven't hit the surface).
    int layer = 0;
    while (layer < 64 && current_displacement_height < current_ray_sample_height) {
        local_uv += d_uv;
        current_ray_sample_height -= layer_height_interval; // Go down one layer.
        current_displacement_height = sample_heightmap(local_uv, uv_gradient);
        layer += 1;
    }

    // Found first UV above intersection (I think?). Calculate previous UV for weighting.
    float previous_displacement_height = sample_heightmap(local_uv - d_uv, uv_gradient);
    float current_displacment_sample_height_delta = abs(current_displacement_height - current_ray_sample_height);
    float previous_displacment_sample_height_delta = abs(previous_displacement_height - (current_ray_sample_height + layer_height_interval));
    float uv_weight = current_displacment_sample_height_delta / (current_displacment_sample_height_delta + previous_displacment_sample_height_delta);
    vec2 final_uv = mix(local_uv - d_uv, local_uv, uv_weight);

    return final_uv;
}

// Ray-march and keep track of the highest depth encountered. If that highest depth intersects with the view direction ray before the POM uv depth does, we have a shadow.
bool is_pom_uv_shadowed(in vec2 local_uv) {
    // TODO: logic.
    return true;
}
