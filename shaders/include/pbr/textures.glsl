#if !defined INCLUDE_TEXTURES
    #define INCLUDE_TEXTURES

    #include "/include/utility/bits.glsl"

    vec4 read_texture(sampler2D tex, vec2 uv) {
        return textureGrad(tex, uv, dFdx(uv), dFdy(uv));
    }

    // colortex1: RGBA32UI
    void unpack_colortex1_read(uvec4 colortex_read, out vec4 normal_map_read, out vec4 specular_map_read, out vec2 lightmap_uv, out vec2 uv) {
        #if NORMAL_MAPPING == 1
            normal_map_read = unpackUnorm4x8(colortex_read.r);
        #else
            // get usual face world space normal
            normal_map_read = vec4(unpackUnorm2x16(colortex_read.r), 0.0, 0.0);
        #endif
        #if SPECULAR_MAPPING == 1
            specular_map_read = unpackUnorm4x8(colortex_read.g);
        #endif
        lightmap_uv = unpackUnorm2x16(colortex_read.b);
        #if POM == 1
            uv = unpackUnorm2x16(colortex_read.a);
        #endif
    }
#endif
