#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/math/convenience.glsl"

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0 */

    layout(location = 0) out vec4 color;

    #include "/include/settings.glsl"
    #include "/include/buffers.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/debug_text.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/color/turbo_colormap_curve.glsl"

    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    vec2 WINDOW_CENTER = vec2(1703, 947) / windowDimensions;
    vec2 WINDOW_SCALE = vec2(0.1);
    vec2 BOTTOM_LEFT = WINDOW_CENTER + 0.5 * WINDOW_SCALE;
    #if DEBUG_COVER_SCREEN == 0
        vec2 new_uv = (uv - BOTTOM_LEFT) / WINDOW_SCALE;
    #else
        vec2 new_uv = uv;
    #endif

    vec4 sample_colortex();
    vec4 sample_shadowtex();
    vec4 sample_depthtex();
    vec4 sample_shadowcolor();

    void main() {
        color = texture(colortex0, uv);

        #if DEBUG_COVER_SCREEN == 1
            #if DEBUG_VIEW == 1
                #if DEBUG_BUFFER <= 31
                    // 0-31.
                    color = sample_colortex();
                #elif DEBUG_BUFFER <= 33
                    // 32-33.
                    color = vec4(interpolate_turbo(sample_depthtex().r), 1.0);
                #elif DEBUG_BUFFER <= 34
                    // 34.
                    color = sample_shadowtex();
                #elif DEBUG_BUFFER <= 36
                    // 35-36.
                    color = sample_shadowcolor();
                #endif
            #endif
        #else
            vec2 screen_uv = gl_FragCoord.xy / windowDimensions;

            if (all(lessThanEqual(abs(screen_uv - WINDOW_CENTER), WINDOW_SCALE))) { // scaling for rendering debug view in bottom left quadratn
                #if DEBUG_VIEW == 1
                    #if DEBUG_BUFFER <= 31
                        // 0-31.
                        color = sample_colortex();
                    #elif DEBUG_BUFFER <= 33
                        // 32-33.
                        color = vec4(interpolate_turbo(sample_depthtex().r), 1.0);
                    #elif DEBUG_BUFFER <= 34
                        // 34.
                        color = sample_shadowtex();
                    #elif DEBUG_BUFFER <= 36
                        // 35-36.
                        color = sample_shadowcolor();
                    #endif
                #endif
            }
        #endif

        // sixthsurge's text renderer
    }

    // -----------------------
    //     Implementations
    // -----------------------

    vec4 sample_colortex() {
        #if DEBUG_BUFFER == 1 // bitpacked data. currently display normals
            Material material;
            init_material_unpacked_colortex_read(material, uv);
            return vec4(material.normal, 1.0);
        #elif DEBUG_BUFFER == 2
            return texture(colortex2, new_uv);
        #elif DEBUG_BUFFER == 3
            return texture(colortex3, new_uv);
        #elif DEBUG_BUFFER == 4 // AO.
            float ao_factor = texture(colortex4, new_uv).r;
            return vec4(vec3(ao_factor), 1.0);
        #elif DEBUG_BUFFER == 5
            return texture(colortex5, new_uv);
        #elif DEBUG_BUFFER == 6 // Bloom.
            return texture(colortex6, new_uv);
        #elif DEBUG_BUFFER == 7
            return texture(colortex7, new_uv);
        #elif DEBUG_BUFFER == 8
            return texture(colortex8, new_uv);
        #elif DEBUG_BUFFER == 9
            return texture(colortex9, new_uv);
        #elif DEBUG_BUFFER == 10
            return texture(colortex10, new_uv);
        #elif DEBUG_BUFFER == 11
            return texture(colortex11, new_uv);
        #elif DEBUG_BUFFER == 12
            return texture(colortex12, new_uv);
        #elif DEBUG_BUFFER == 13
            return texture(colortex13, new_uv);
        #elif DEBUG_BUFFER == 14
            return texture(colortex14, new_uv);
        #elif DEBUG_BUFFER == 15
            return texture(colortex15, new_uv);
        #elif DEBUG_BUFFER == 16
            return texture(colortex16, new_uv);
        #elif DEBUG_BUFFER == 17
            return texture(colortex17, new_uv);
        #elif DEBUG_BUFFER == 18
            return texture(colortex18, new_uv);
        #elif DEBUG_BUFFER == 19
            return texture(colortex19, new_uv);
        #elif DEBUG_BUFFER == 20
            return texture(colortex20, new_uv);
        #elif DEBUG_BUFFER == 21
            return texture(colortex21, new_uv);
        #elif DEBUG_BUFFER == 22
            return texture(colortex22, new_uv);
        #elif DEBUG_BUFFER == 23
            return texture(colortex23, new_uv);
        #elif DEBUG_BUFFER == 24
            return texture(colortex24, new_uv);
        #elif DEBUG_BUFFER == 25
            return texture(colortex25, new_uv);
        #elif DEBUG_BUFFER == 26
            return texture(colortex26, new_uv);
        #elif DEBUG_BUFFER == 27
            return texture(colortex27, new_uv);
        #elif DEBUG_BUFFER == 28
            return texture(colortex28, new_uv);
        #elif DEBUG_BUFFER == 29
            return texture(colortex29, new_uv);
        #elif DEBUG_BUFFER == 30
            return texture(colortex30, new_uv);
        #elif DEBUG_BUFFER == 31
            return texture(colortex31, new_uv);
        #else
            return texture(colortex0, new_uv);
        #endif
    }

    vec4 sample_depthtex() {
        float depth = texture(depthtex0, new_uv).r;
        return vec4(vec3(depth), 1.0);
    }

    vec4 sample_shadowtex() {
        #if DEBUG_BUFFER == 33
            return texture(shadowtex0, new_uv);
        #elif DEBUG_BUFFER == 34
            return texture(shadowtex1, new_uv);
        #else
            return vec4(0.0);
        #endif
    }

    vec4 sample_shadowcolor() {
        #if DEBUG_BUFFER == 35
            return texture(shadowtex0, new_uv);
        #elif DEBUG_BUFFER == 36
            return texture(shadowtex1, new_uv);
        #else
            return vec4(1., 0., 0., 1.);
        #endif
    }
#endif
