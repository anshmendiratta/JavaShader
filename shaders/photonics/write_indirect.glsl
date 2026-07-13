#if !defined INCLUDE_PHOTONICS_WRITE_INDIRECT
    #define INCLUDE_PHOTONICS_WRITE_INDIRECT

    writeonly uniform image2D radiosity_indirect_image; // taken from: https://github.com/Essentuan/photon/blob/aea7aa0b614f4c0499e0ca8472d11305b2901450/shaders/photonics/write_indirect.glsl

    void write_indirect(vec3 color) {
        imageStore(radiosity_indirect_image, ivec2(gl_FragCoord.xy), vec4(color, 1.));
    }
#endif