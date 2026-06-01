#if !defined INCLUDE_SETTINGS
    #define INCLUDE_SETTINGS

    // ------------------
    //     Atmosphere
    // ------------------

    #define FOG 1 // Enables fog. [0 1]

    #define FOG_DENSITY 6.0 // How quickly the fog starts in your render distance. Lower is faster. [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]

    // ---------------
    //     Shadows
    // ---------------

    #define SHADOWS 1 // Enables/disables shadows. [0 1]

    #define SHADOW_MAP_RESOLUTION 1024 // Shadow map resolution in pixels. [512 1024 2048 4096 8192]
    #define SHADOW_BIAS 1.0 // Bias used to mitigate shadow acne. [1.0 1.1 1.2 1.3 1.4 1.5]
    #define PCF_SHADOW_RADIUS 1 // Spacing of pixels used for shadow blur sampling. [1 2 3 4 5 6 7 8]
    #define SHADOW_RANGE 4 // `width/height / 2 - 1` of the box kernel used for shadow blurring. [1 2 3 4 5 6 7 8]
    #define SHADOW_DISTANCE_MULTIPLIER 2 // This multiplies the possible shadow distance (256 blocks). [1 2 3 4]

    // TODO: add a description for some of these
    #define RSM 1 // Enables/disables reflective shadow maps. [0 1]
    #define RSM_SAMPLE_COUNT 4 // Number of values to use for RSM evaluation interpolation. Higher is worse performance. [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
    #define RSM_SAMPLE_RADIUS 2.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
    #define RSM_BRIGHTNESS 5.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]

    // ----------------------
    //     Waving objects
    // ----------------------

    #define WAVING_FOLIAGE 0 // Enables the waving motion in plants/foliage. [0 1]

    #define FOLIAGE_WAVE_OFFSET 2 / 7
    #define FOLIAGE_WAVE_SPEED 0.5
    #define FOLIAGE_WAVE_AMPLITUDE 0.09

    #define WAVING_WATER 0 // Enables waves on the water. [0 1]

    // ------------------------
    //     Indirect lighting
    // ------------------------

    #define AMBIENT_OCCLUSION 1 // Enables ambient occlusion. [0 1]
    #define AMBIENT_INTENSITY 1.0 // How much AO is applied. Higher values increase AO. [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0]

    #define VANILLA_AO 1.0 // Determines how much of vanilla ambient occlusion is applied. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

    #define SSAO_SAMPLE_COUNT 16 // [16 32 64 128]
    #define SSAO_RADIUS 2.5 // [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5]
    #define SSAO_BIAS 0.0 // [0.0 0.01 0.05 0.01 0.015 0.02 0.025 0.03 0.035]

    #define SSAO_BLUR_RADIUS 8 // Pixel radius used for blur. Higher is softer. [4 8 12 16 20 24 28 32 36]

    // -----------
    //     Sky
    // -----------

    #define SUN_MOON_SIZE_SCALAR 1.0 // Multiplier of the sun/moon's default size. [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8]
    #define SUN_MOON_AXIS_ROTATION 0 // Rotation of the sun/moon along their axis towards the player. [-45 -40 -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45]

    #define BLOCKLIGHT_INTENSITY_MULTIPLIER 1.0 // Blocklight luminosity intensity. [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
    #define BLOCKLIGHT_R 0.3 // Blocklight color red content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define BLOCKLIGHT_G 0.2 // Blocklight color green content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define BLOCKLIGHT_B 0.1 // Blocklight color blue content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

    #define SUNLIGHT_INTENSITY 0.4 // Sun brightness. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define MOONLIGHT_INTENSITY 0.1 // Moon brightness. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define SKYLIGHT_INTENSITY_MULTIPLIER 0.4 // Sun brightness. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

    // TODO: organize this more nicely
    #define SKY_COLOR_HORIZON vec3(0.3, 0.58, 1.0)
    #define FOG_COLOR SKY_COLOR_HORIZON
    #define BLOCKLIGHT_COLOR vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)
    #define SUNLIGHT_COLOR vec3(SUNLIGHT_INTENSITY)
    #define SKYLIGHT_COLOR vec3(0.4)

    // -------------
    //     Water
    // -------------

    #define WATER_WAVE_AMPLITUDE 0.01 // How high a water wave can go. Do not interpret this value as blocks/meters. [0.00 0.01 0.02 0.03 0.04]

    // -----------------
    //     Materials
    // -----------------

    #define POM 0 // Enables LabPBR parallax occlusion mapping. [0 1]
    #define SSS 0 // Enables subsurface scattering. [0 1]

    #define EMISSION_STRENGTH 1.0 // Determines how bright emissive objects appear. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5]

    #define POM_HEIGHT_SCALE 0.06 // Changes the depth perceived in POM textures. [0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.25 0.5 0.75 1.0]
    #define POM_LAYERS 8 // Number of layers used for POM. Higher gives more detail. [8 16 32 64 128]
    #define POM_DEPTH_WRITE 1 // Enables whether or not the parallax mapping can allow shadowing. [0 1]

    #define SSS_SAMPLE_COUNT 16 // The number of samples used for SSS. Higher is better with diminshing returns. [1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
    #define SSS_STRENGTH 15.0 // How bright subsurface scattering appears. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 5.25 5.5 5.75 6.0 6.25 6.5 6.75 7.0 7.25 7.5 7.75 8.0 8.25 8.5 8.75 9.0 9.25 9.5 9.75 10.0 10.25 10.5 10.75 11.0 11.25 11.5 11.75 12.0 12.25 12.5 12.75 13.0 13.25 13.5  13.75 14.0 14.25 14.5 14.75 15.0]
    #define OPTICAL_DENSITY_MULTIPLIER 2.0 // Scalar for how optically dense SSS materials are. Higher values localize the effect. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0]

    // ---------------------------
    //     Screen Space Passes
    // ---------------------------

    #define BLOOM 1 // Enables a halo around bright objects. [0 1]

    #define BLOOM_RADIUS 1 // Determines the distance of samples used for blurring. Higher increases blue but introduces more banding. [1 2 3 4 5 6 7 8 9 10]
    #define BLOOM_INTENSITY 0.25 // Percentage bias towards the bloom HDR buffer. Higher values increase the bloom effect. [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8]

    #define SSR 1 // Enables/disables screen-space reflections. [0 1]
    #define SSR_STEPS 16 // Raymarching steps to use for screen-space reflections. Higher values result in more accurate reflections at the cost of performance. [2 4 6 8 10 12 14 16 18 20 22 24]
    #define SSR_QUALITY 10 // A factor into how small the raymarching steps for SSR are. Higher values result in better quality. [1 2 4 6 8 10]
    #define SSR_VISIBILITY 1.0 // How intensely reflections overwrite the material's color. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    #define SSR_ENERGY_THRESHOLD 0.95 // An arbitary number that determines all surfaces that can screen-space reflect. [0.0 0.01 0.02 0.03 0.04 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

    // ----------------------
    //     Smart Denoiser
    // ----------------------

    #define SMART_DENOISING 1 // Enable/disable the denoiser. [0 1]

    #define SIGMA 5.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]
    #define K_SIGMA 2.0 // [1.0 1.5 2.0 2.5 3.0]
    #define THRESHOLD 0.10 // [0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.2]

    // -----------
    //     Dev
    // -----------

    #define DEBUG_VIEW 0 // Enables/disables the debug view for buffers. [0 1]
    #define DEBUG_BUFFER 0 // colortex0-15, depthtex0, shadowtex0-1, shadowcolor0. [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19]
    #define DEBUG_COVER_SCREEN 0 // Toggles between the debug output rendering to a fourth of the screen and the entire screen. [0 1]
#endif
