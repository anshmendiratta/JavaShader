#if !defined INCLUDE_PARALLAX
    #define INCLUDE_PARALLAX
    // TOOD: fix everything.

    #include "/include/math/convenience.glsl"
    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/depth.glsl"

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
        // More layers when viewing at grazing angles
        float layer_depth = 1.0 / float(POM_LAYERS);

        // Start at the top surface
        vec2 current_uv = local_uv;
        float current_height = 1.0;

        // Calculate UV offset per layer - proper parallax offset
        vec2 uv_offset = (view_direction_tangent_space.xy / -view_direction_tangent_space.z) * (POM_HEIGHT_SCALE * layer_depth);

        // Early exit for flat surfaces
        float initial_height = _sample_heightmap(local_uv);
        if (initial_height < 0.01) {
            return local_uv;
        }

        // Ray march down until we hit the surface
        float sampled_height = _sample_heightmap(current_uv);
        int layer = 0;
        while (layer < POM_LAYERS && current_height > sampled_height) {
            current_uv += uv_offset;
            current_height -= layer_depth;
            sampled_height = _sample_heightmap(current_uv);
            layer += 1;
        }

        // Linear interpolation between last two samples for smooth transitions
        vec2 previous_uv = current_uv - uv_offset;
        float previous_height = current_height + layer_depth;
        float previous_sampled = _sample_heightmap(previous_uv);

        // Calculate the intersection point between the two samples
        float height_diff_before = previous_height - previous_sampled;
        float height_diff_after = sampled_height - current_height;

        // Prevent division by zero and ensure smooth interpolation
        float total_diff = height_diff_before + height_diff_after;
        float weight = (total_diff > 0.0001) ? (height_diff_before / total_diff) : 0.5;
        weight = clamp01(weight);

        vec2 final_uv = mix(previous_uv, current_uv, weight);

        // Mostly inspired by Bliss (Xonk): https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/dimensions/all_solid.fsh#L392
        #if POM_DEPTH_WRITE == 1
            vec3 fragment_with_pom_view_space_position = fragment_view_space_position + layer * transpose(TBN_matrix) * vec3(uv_offset, 1.0);
            vec4 fragment_with_pom_clip_space_position = view_to_clip(fragment_with_pom_view_space_position);
            // vec3 fragment_with_pom_screen_space_position = clip_to_ndc(fragment_with_pom_clip_space_position) * 0.5 + 0.5;
            // gl_FragDepth = fragment_with_pom_clip_space_position.z / fragment_with_pom_clip_space_position.w;
            gl_FragDepth = fragment_with_pom_clip_space_position.z / fragment_with_pom_clip_space_position.w * 0.5 + 0.5;
        #endif

        return final_uv;
    }

    // Ray-march and keep track of the highest depth encountered. If that highest depth intersects with the view direction ray before the POM uv depth does, we have a shadow.
    bool is_pom_uv_shadowed(in vec2 local_uv) {
        // TODO: logic.
        return true;
    }
#endif