// Courtesy of https://github.com/BelmuTM/Noble/blob/b9677c7a7ee9c43420bcbe639b4348968a27c570/shaders/include/uniforms.glsl.

#if !defined INCLUDE_UNIFORMS
    #define INCLUDE_UNIFORMS

    uniform float alphaTestRef = 0.1;

    // Uniforms
    uniform vec3 skyColor;
    uniform vec3 fogColor;

    uniform vec3 shadowLightPosition;

    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;

    uniform float viewWidth;
    uniform float viewHeight;
    uniform float aspectRatio;
    uniform vec2 windowDimensions;

    uniform vec2 viewSize;
    uniform vec2 texelSize;
    uniform ivec2 atlasSize;

    uniform int worldTime;
    uniform int framemod;
    uniform int frameCounter;
    uniform float frameTime;
    uniform float frameTimeCounter;

    uniform int isEyeInWater;
    uniform int hideGUI;

    uniform float centerDepthSmooth;
    uniform float rainStrength;
    uniform float wetness;
    uniform float sunAngle;

    uniform int renderStage;

    uniform int biome_category;
    uniform int biome_precipitation;

    uniform float biome_arid;

    uniform float biome_may_rain;
    uniform float biome_may_sandstorm;

    uniform float near;
    uniform float far;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferPreviousModelView;

    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferPreviousModelViewInverse;

    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferPreviousProjection;

    uniform mat4 shadowModelView;
    uniform mat4 shadowModelViewInverse;
    uniform mat4 shadowProjection;
    uniform mat4 shadowProjectionInverse;

    // Samplers

    uniform sampler2D gtexture;

    uniform sampler2D noisetex;

    uniform sampler2D colortex0;
    uniform usampler2D colortex1;
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;
    uniform sampler2D colortex4;
    uniform sampler2D colortex5;
    uniform sampler2D colortex6;
    uniform sampler2D colortex7;
    uniform sampler2D colortex8;
    uniform sampler2D colortex10;
    uniform sampler2D colortex11;
    uniform sampler2D colortex12;
    uniform sampler2D colortex13;
    uniform sampler2D colortex14;
    uniform sampler2D colortex15;

    uniform sampler2D depthtex0;
    uniform sampler2D depthtex1;
    uniform sampler2D depthtex2;

    uniform sampler2D shadowtex0;
    uniform sampler2D shadowtex1;
    uniform sampler2D shadowcolor0;

    uniform sampler2D normals;
    uniform sampler2D specular;
    uniform sampler2D lightmap;

#endif
