// NOTE: this exists so that each propagation does not depend on compute shader execution order (on the image)
#ifdef STAGE_COMPUTE
    layout(local_size_x = 32) in;
    const ivec3 workGroups = ivec3(4, 128, 128);

    writeonly uniform image3D floodfill_map_copy;

    uniform sampler3D floodfill_map;
    uniform sampler3D voxel_map;

    void main() {
        ivec3 pos = ivec3(gl_GlobalInvocationID);
        vec4 light_level = texelFetch(floodfill_map, pos, 0);
        imageStore(floodfill_map_copy, pos, light_level);
    }
#endif
