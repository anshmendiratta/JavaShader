#if !defined INCLUDE_TEXTURES
    #define INCLUDE_TEXTURES

    #include "/include/utility/bits.glsl"

    // colortex1: RGBA32UI
    void unpack_colortex1_read(uvec4 colortex_read, out vec4 normal_map_read, out vec4 specular_map_read, out vec2 lightmap_uv, out uint material_id) {
        normal_map_read = unpackUnorm4x8(colortex_read.r);
        specular_map_read = unpackUnorm4x8(colortex_read.g);
        lightmap_uv = unpackUnorm2x16(colortex_read.b);
        material_id = uint(colortex_read.a);
    }
#endif
