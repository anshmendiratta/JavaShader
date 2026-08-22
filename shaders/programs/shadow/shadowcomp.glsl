#ifdef STAGE_COMPUTE
    layout(local_size_x = 32) in;
    const ivec3 workGroups = ivec3(4, 128, 128);

    writeonly uniform image3D floodfill_map;

    uniform sampler3D floodfill_map_copy;
    uniform usampler3D voxel_map;

    ivec3 voxel_offsets[6] = ivec3[](
    ivec3(1, 0, 0),
    ivec3(0, 1, 0),
    ivec3(1, 0, 1),
    ivec3(-1, 0, 0),
    ivec3(0, -1, 0),
    ivec3(0, 0, -1)
    );

    #include "/include/ids.glsl"
    #include "/include/utility/voxelization.glsl"
    #include "/include/lighting/floodfill.glsl"

    void main() {
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        ivec3 previous_pos = ivec3(vec3(pos) + floor(cameraPosition) - floor(previousCameraPosition));
        uint block_id = texelFetch(voxel_map, pos, 0).x;

        vec3 light_level = vec3(0.);

        if (block_id != 0u || block_id >= 10201u) {
            // not emissive or tinting block
            light_level += texelFetch(floodfill_map_copy, previous_pos, 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[0], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[1], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[2], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[3], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[4], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;
            light_level += texelFetch(floodfill_map_copy, clamp(previous_pos + voxel_offsets[5], ivec3(0), VOXEL_VOLUME_SIZE - 1), 0).rgb;

            light_level /= 7.;

            if (block_id >= 10201u) {
                // tinting block
                uint idx = min(block_id - 10201u, blocklight_tint.length() - 1u);
                light_level *= pow2(blocklight_tint[idx]);
            }
        } else {
            // emissive block
            uint idx = min(block_id - 10003u, blocklight_color.length() - 1u);
            light_level = pow2(blocklight_color[idx]);
        }

        imageStore(floodfill_map, pos, vec4(light_level, 0.));
    }
#endif
