#if !defined INCLUDE_INTERSECT
    #define INCLUDE_INTERSECT

    // -------------------------
    //     Ray intersections
    // -------------------------
    // these all return the position of the intersection

    vec3 ray_intersect_plane(const in vec3 frag_pos_world, in vec3 ray_world, float plane_altitude) {
        if (sign(frag_pos_world.y - plane_altitude) == -sign(ray_world.y)) return vec3(1., 0., 0.); // can't intersect

        ray_world /= ray_world.y;
        float vertical_step_count = abs(frag_pos_world.y - plane_altitude);
        return frag_pos_world + vertical_step_count * ray_world;
    }

    // assumes you are at the center of the hemisphere
    vec3 ray_internal_intersect_hemisphere(const in vec3 frag_pos_world, const in vec3 ray_world, float hemi_radius) {
        return frag_pos_world + hemi_radius * normalize(ray_world);
    }
#endif
