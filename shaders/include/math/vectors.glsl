#if !defined INCLUDE_VECTORS
    #define  INCLUDE_VECTORS

    // from https://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    mat4 _axis_angle_rotation_matrix(vec3 axis, float angle) {
        axis = normalize(axis);
        float s = sin(angle);
        float c = cos(angle);
        float oc = 1.0 - c;

        return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
            oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
            oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
            0.0, 0.0, 0.0, 1.0);
    }

    vec3 rotate_vector_axis_angle(vec3 vector, vec3 axis, float angle) {
        vec4 converted_vector = vec4(vector, 1.0);
        mat4 rotation_matrix = _axis_angle_rotation_matrix(axis, angle);

        return (rotation_matrix * converted_vector).xyz;
    }

    vec4 rotate_vector_axis_angle(vec4 vector, vec3 axis, float angle) {
        vec4 converted_vector = vector;
        mat4 rotation_matrix = _axis_angle_rotation_matrix(axis, angle);

        return rotation_matrix * converted_vector;
    }
#endif
