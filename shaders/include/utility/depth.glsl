#if !defined INCLUDE_DEPTH_CONVERSION
    #define INCLUDE_DEPTH_CONVERSION

    #include "/include/uniforms.glsl"

    // NOTE: the z values used below are BETWEEN the near and far planes and cannot substitute `view_space_position.z` !
    // NOTE: the non-linear conversion from z to depth is _proportional_ to 1/z, not equal to it
    // https://learnopengl.com/Advanced-OpenGL/Depth-testing

    // _lower_ depth values in [0, 1] are given larger precision because they're closer to the camera

    float z_to_depth(float z) {
        return (1.0 / z - 1.0 / near) / (1.0 / far - 1.0 / near);
    }

    float depth_to_z(float depth) {
        return (near * far) / (depth * (near - far) + far);
    }
#endif
