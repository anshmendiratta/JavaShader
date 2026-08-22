#if !defined INCLUDE_VOXELIZATION
    #define INCLUDE_VOXELIZATION

    #include "/include/uniforms.glsl"
    #include "/include/settings.glsl"

    #include "/include/math/convenience.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    vec3 _feet_to_voxel_space(in vec3 feet_pos);
    vec3 _voxel_to_feet_space(in vec3 voxel_pos);

    // --------------------
    //     Voxelization
    // --------------------

    struct VoxelData {
        uint block_id;
    };

    const ivec3 VOXEL_VOLUME_SIZE = ivec3(VOXEL_AREA);

    bool is_inside_voxel_radius(in vec3 voxel_pos) {
        voxel_pos /= vec3(VOXEL_VOLUME_SIZE);
        return clamp01(voxel_pos) == voxel_pos;
    }

    #if !defined STAGE_COMPUTE
        VoxelData get_voxel_data(in vec3 voxel_pos) {
            uint block_id = imageLoad(voxel_map, ivec3(voxel_pos)).x;
            return VoxelData(block_id);
        }
    #endif

    uint compute_voxel_data(in uint block_id) {
        return block_id == 11000u || block_id == 10000u ? 0u : max1(block_id);
    }

    vec3 feet_to_voxel_space(in vec3 feet_pos) {
        return feet_pos + fract(cameraPosition) + (0.5 * float(VOXEL_VOLUME_SIZE));
    }

    vec3 voxel_to_feet_space(in vec3 voxel_pos) {
        return voxel_pos - fract(cameraPosition) - (0.5 * float(VOXEL_VOLUME_SIZE));
    }
#endif
