#if !defined INCLUDE_PIPELINE
    #define INCLUDE_PIPELINE

    #include "/include/settings.glsl"

    const int shadowMapResolution = SHADOW_MAP_RESOLUTION; // Shadow map resolution in pixels. [512 1024 2048 4096]
    const float shadowDistance = 160.0;
    const bool shadowtex0Nearest = true;
    const bool shadowtex1Nearest = true;
    const bool shadowcolor0Nearest = true;

    const float ambientOcclusionLevel = VANILLA_AO;

    const float sunPathRotation = -30.0;
#endif
