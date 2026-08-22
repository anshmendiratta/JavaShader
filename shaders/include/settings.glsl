#if !defined INCLUDE_SETTINGS
    #define INCLUDE_SETTINGS

    // ------------------
    //     Atmosphere
    // ------------------

    #define FOG 0 // Enables fog. [0 1]

    #define FOG_DENSITY 6.0 // How quickly the fog starts in your render distance. Lower is faster. [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]

    // ---------------
    //     Shadows
    // ---------------

    #define SHADOWS 1 // Enables/disables shadows. [0 1]
    #define CONTACT_SHADOWS 1 // [0 1]

    #define SHADOW_MAP_RESOLUTION 1024 // Shadow map resolution in pixels. [512 1024 2048 4096 8192]

    #define PCSS_SAMPLES 16

    #define SHADOW_BLUR_SAMPLES 16
    #define SHADOW_DISTANCE_MULTIPLIER 2 // This multiplies the possible shadow distance (256 blocks). [1 2 3 4]
    #define SHADOW_DISTORTION 0.9

    #define CONTACT_SHADOW_STEPS 8
    #define CONTACT_SHADOW_STEP_SIZE 1

    #define PIXELATED_SHADOWS 0 // [0 1]
    #define PIXELATED_SHADOWS_RESOLUTION 16.0 // [2.0 4.0 8.0 16.0]

    // --------------------
    //     Voxelization
    // --------------------

    #define VOXEL_AREA 128
    #define VOXEL_RADIUS (VOXEL_AREA / 2)

    // ----------
    //     GI
    // ----------

    #define RSM 0 // Enables/disables reflective shadow maps. [0 1]

    #define RSM_SAMPLES 4 // Number of values to use for RSM evaluation interpolation. Higher is worse performance. [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
    #define RSM_RADIUS 2.5 // [0.1 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
    #define RSM_BRIGHTNESS 5.0 // [1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]

    // ----------------------
    //     Waving objects
    // ----------------------

    #define WAVING_FOLIAGE 1 // Enables the waving motion in plants/foliage. [0 1]
    #define WAVING_WATER 0 // Enables waves on the water. [0 1]

    #define FOLIAGE_WAVE_OFFSET 2 // 7
    #define FOLIAGE_WAVE_SPEED 0.5 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    #define FOLIAGE_WAVE_AMPLITUDE 0.09 // [0.03 0.05 0.07 0.09 0.11 0.13 0.15 0.17 0.19]

    // ------------------------
    //     Indirect lighting
    // ------------------------

    #define AMBIENT_OCCLUSION 1 // Enables ambient occlusion. [0 1]

    #define VANILLA_AO 0.0 // Determines how much of vanilla ambient occlusion is applied. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    #define AO_STRENGTH 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]

    #define SSAO_SAMPLES 8 // [8 16 32 64 128]
    #define SSAO_RADIUS 2.5 // [0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0]
    #define SSAO_BLUR_RADIUS 8 // Pixel radius used for blur. Higher is softer. [4 8 12 16 20 24 28 32 36]

    // -----------
    //     Sky
    // -----------

    #define PBR_SKY 1.0 // Enables/disables the PBR sky. [0.0 1.0]

    #define LIGHT_INTENSITY 11.0 // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0]
    #define S_R 0.18 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0]
    #define S_M 0.06 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0]
    #define S_S 0.08 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0]
    #define RAYLEIGH_SCATTER_R 0.33 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0 1.02 1.04 1.06 1.08 1.1 1.12 1.14 1.16 1.18 1.2 1.22 1.24 1.26 1.28 1.3 1.32 1.34 1.36 1.38 1.4 1.42 1.44 1.46 1.48 1.5 1.52 1.54 1.56 1.58 1.6 1.62 1.64 1.66 1.68 1.7 1.72 1.74 1.76 1.78 1.8 1.82 1.84 1.86 1.88 1.9 1.92 1.94 1.96 1.98 2.0]
    #define RAYLEIGH_SCATTER_G 0.78 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0 1.02 1.04 1.06 1.08 1.1 1.12 1.14 1.16 1.18 1.2 1.22 1.24 1.26 1.28 1.3 1.32 1.34 1.36 1.38 1.4 1.42 1.44 1.46 1.48 1.5 1.52 1.54 1.56 1.58 1.6 1.62 1.64 1.66 1.68 1.7 1.72 1.74 1.76 1.78 1.8 1.82 1.84 1.86 1.88 1.9 1.92 1.94 1.96 1.98 2.0]
    #define RAYLEIGH_SCATTER_B 1.89 // [0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0 1.02 1.04 1.06 1.08 1.1 1.12 1.14 1.16 1.18 1.2 1.22 1.24 1.26 1.28 1.3 1.32 1.34 1.36 1.38 1.4 1.42 1.44 1.46 1.48 1.5 1.52 1.54 1.56 1.58 1.6 1.62 1.64 1.66 1.68 1.7 1.72 1.74 1.76 1.78 1.8 1.82 1.84 1.86 1.88 1.9 1.92 1.94 1.96 1.98 2.0]

    #define SUN_MOON_SIZE_SCALAR 1.0 // Multiplier of the sun/moon's default size. [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8]
    #define SUN_MOON_AXIS_ROTATION 0 // Rotation of the sun/moon along their axis towards the player. [-45 -40 -35 -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30 35 40 45]

    #define BLOCKLIGHT_INTENSITY 3.0 // Blocklight luminosity intensity. [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
    #define BLOCKLIGHT_R 0.4 // Blocklight color red content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define BLOCKLIGHT_G 0.2 // Blocklight color green content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
    #define BLOCKLIGHT_B 0.1 // Blocklight color blue content. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

    #define SUNLIGHT_INTENSITY 1.50 // Sun brightness. []
    #define MOONLIGHT_INTENSITY 2e-2 // Moon brightness. []

    // TODO: organize this more nicely
    #define BLOCKLIGHT_COLOR vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)
    #define SUNLIGHT_COLOR vec3(SUNLIGHT_INTENSITY)
    #define SKYLIGHT_COLOR vec3(1.)

    // -------------
    //     Water
    // -------------

    #define WATER_WAVE_AMPLITUDE 3e-5 // How high a water wave can go. Do not interpret this value as blocks/meters. [0.5 1.0 1.5 2.0]

    // -----------------
    //     Materials
    // -----------------

    #define POM 0 // Enables LabPBR parallax occlusion mapping. [0 1]
    #define SSS 1 // Enables subsurface scattering. [0 1]

    #define EMISSION_STRENGTH 20.0 // Determines how bright emissive objects appear. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5]

    #define POM_HEIGHT_SCALE 0.06 // Changes the depth perceived in POM textures. [0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.25 0.5 0.75 1.0]
    #define POM_LAYERS 8 // Number of layers used for POM. Higher gives more detail. [8 16 32 64 128]
    #define POM_DEPTH_WRITE 1 // Enables whether or not the parallax mapping can allow shadowing. [0 1]

    #define SSS_SAMPLES 8 // The number of samples used for SSS. Higher is better with diminshing returns. [1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32]
    #define SSS_STRENGTH 30.0 // How bright subsurface scattering appears. [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 5.25 5.5 5.75 6.0 6.25 6.5 6.75 7.0 7.25 7.5 7.75 8.0 8.25 8.5 8.75 9.0 9.25 9.5 9.75 10.0 10.25 10.5 10.75 11.0 11.25 11.5 11.75 12.0 12.25 12.5 12.75 13.0 13.25 13.5  13.75 14.0 14.25 14.5 14.75 15.0]
    #define OPTICAL_DENSITY_MULTIPLIER 5.0 // Scalar for how optically dense SSS materials are. Higher values localize the effect.

    // ---------------------------
    //     Screen Space Passes
    // ---------------------------

    #define BLOOM 1 // Enables a halo around bright objects. [0 1]

    #define BLOOM_RADIUS 1 // Determines the distance of samples used for blurring. Higher increases blue but introduces more banding. [1 2 3 4 5 6 7 8 9 10]
    #define BLOOM_STRENGTH 0.08 // Percentage bias towards the bloom HDR buffer. Higher values increase the bloom effect. [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10]

    #define SSR 1 // Enables/disables screen-space reflections. [0 1]
    #define SSR_STEPS 16 // Raymarching steps to use for screen-space reflections. Higher values result in more accurate reflections at the cost of performance. [2 4 6 8 10 12 14 16 18 20 22 24]
    #define SSR_QUALITY 10 // A factor into how small the raymarching steps for SSR are. Higher values result in better quality. [1 2 4 6 8 10]
    #define SSR_VISIBILITY 1.0 // How intensely reflections overwrite the material's color. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    #define SSR_ENERGY_THRESHOLD 0.95 // An arbitary number that determines all surfaces that can screen-space reflect. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
    #define SSR_ACCUMULATION 1 // [0 1]

    #define ROUGH_REFLECTIONS 1 // [0 1]

    // ---------------------
    //     Anti aliasing
    // ---------------------

    #define TAA 0 // [0 1]

    // ---------------------
    //     Color grading
    // ---------------------

    #define PURKINJE_SHIFT 1 // Makes night more desaturated. [0 1]

    #define TONEMAP 0 // [0 1]

    // -----------
    //     Dev
    // -----------

    #define DEBUG_VIEW 0 // Enables/disables the debug view for buffers. [0 1]
    #define DEBUG_BUFFER 0 // colortex0-31, depthtex0, shadowtex0-1, shadowcolor0-1. [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36]
    #define DEBUG_COVER_SCREEN 0 // Toggles between the debug output rendering to a fourth of the screen and the entire screen. [0 1]

    #define WHITEWORLD 0 // Enables/disables colors. [0 1]
#endif
