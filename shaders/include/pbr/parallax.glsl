#if !defined INCLUDE_PARALLAX
    #define INCLUDE_PARALLAX
    // TOOD: fix everything.

    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/depth_conversion.glsl"

    vec2 local_uv_to_atlas(vec2 local_uv, vec2 bottom_left_coord, vec2 texture_size) {
        return fract(local_uv) * texture_size + bottom_left_coord;
    }

    vec2 atlas_uv_to_local(vec2 atlas_uv, vec2 bottom_left_coord, vec2 texture_size) {
        return (atlas_uv - bottom_left_coord) * rcp(texture_size);
    }

    float _sample_heightmap(vec2 uv) {
        // Requires atlas space coordinates for sampling.
        vec2 atlas_uv = local_uv_to_atlas(uv, texture_bottom_left, single_tex_size);
        return textureLod(normals, atlas_uv, 0).a;
    }

    vec2 pom_uv_transform(in vec2 local_uv, /* camera to fragment */ vec3 view_direction_tangent_space, vec3 fragment_view_space_position, mat3 TBN_matrix) {
        int layers_count = int(mix(POM_MIN_LAYERS, POM_MAX_LAYERS, 1.0 - abs(view_direction_tangent_space.z)));
        float layer_height_interval = rcp(float(layers_count));

        vec3 transformed_coordinate = vec3(local_uv, 1.0);
        vec3 d_uv = view_direction_tangent_space * POM_HEIGHT_SCALE * layer_height_interval * rcp(-view_direction_tangent_space.z);

        // Snippet from https://github.com/sixthsurge/photon/blob/40adec318ea608d9f9ba88fcc272730af0899a62/shaders/include/surface/parallax.glsl#L32.
        if (_sample_heightmap(transformed_coordinate.xy) < rcp(255.0)) {
            return local_uv;
        }

        // Advance while the sampling ray is above the heightmap value (i.e. we haven't hit the surface).
        int layer = 0;
        while (layer < layers_count && _sample_heightmap(transformed_coordinate.xy) < transformed_coordinate.z) {
            transformed_coordinate += d_uv;
            layer += 1;
        }

        // Found first UV above intersection. Calculate previous UV for weighting.
        vec3 previous_coordinate = transformed_coordinate - d_uv;
        float previous_displacement_height = _sample_heightmap(previous_coordinate.xy);
        float current_displacement_height = _sample_heightmap(transformed_coordinate.xy);
        float current_height_delta = transformed_coordinate.z - current_displacement_height;
        float previous_height_delta = previous_displacement_height - previous_coordinate.z;
        float uv_weight = current_height_delta / (current_height_delta + previous_height_delta);
        vec2 final_uv = mix(transformed_coordinate.xy, previous_coordinate.xy, uv_weight);

        // FIX: z doesnt work for the depth value
        // Mostly inspired by Bliss (Xonk): https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/dimensions/all_solid.fsh#L392
        #if POM_DEPTH_WRITE == 1
            vec3 fragment_with_pom_view_space_position = fragment_view_space_position + layer * transpose(TBN_matrix) * d_uv;
            vec4 fragment_with_pom_clip_space_position = view_to_clip(fragment_with_pom_view_space_position);
            gl_FragDepth = fragment_with_pom_clip_space_position.z;
        #endif

        return final_uv;
    }

    // Ray-march and keep track of the highest depth encountered. If that highest depth intersects with the view direction ray before the POM uv depth does, we have a shadow.
    bool is_pom_uv_shadowed(in vec2 local_uv) {
        // TODO: logic.
        return true;
    }
#endif
