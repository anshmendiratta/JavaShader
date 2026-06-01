#define DEBUG_QUAD_WINDOW_LENGTH_RATIO rcp(4.0)

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

    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    #include "/include/lighting/subsurface_scattering.glsl"

    #include "/include/color/turbo_colormap_curve.glsl"

    vec2 used_uv = uv; // made mutable so the pom uv can be used

    vec4 sample_colortex() {
        #if DEBUG_BUFFER == 1 // bitpacked data. currently display normals
            Material material;
            init_material_unpacked_colortex_read(material);
            return vec4(material.normal, 1.0);
        #elif DEBUG_BUFFER == 2
            return texture(colortex2, used_uv);
        #elif DEBUG_BUFFER == 3
            return texture(colortex3, used_uv);
        #elif DEBUG_BUFFER == 4 // AO.
            float ao_factor = texture(colortex4, used_uv).r;
            vec3 ao_color = vec3(ao_factor);
            return vec4(ao_color, 1.0);
        #elif DEBUG_BUFFER == 5
            return texture(colortex5, used_uv);
        #elif DEBUG_BUFFER == 6 // Bloom.
            return texture(colortex6, used_uv);
        #elif DEBUG_BUFFER == 7
            return texture(colortex7, used_uv);
        #elif DEBUG_BUFFER == 8
            return texture(colortex8, used_uv);
        #elif DEBUG_BUFFER == 9
            return texture(colortex9, used_uv);
        #elif DEBUG_BUFFER == 10
            return texture(colortex10, used_uv);
        #elif DEBUG_BUFFER == 11
            return texture(colortex11, used_uv);
        #elif DEBUG_BUFFER == 12
            return texture(colortex12, used_uv);
        #elif DEBUG_BUFFER == 13
            return texture(colortex13, used_uv);
        #elif DEBUG_BUFFER == 14
            return texture(colortex14, used_uv);
        #elif DEBUG_BUFFER == 15
            return texture(colortex15, used_uv);
        #else
            return texture(colortex0, used_uv);
        #endif
    }

    vec4 sample_depthtex() {
        float depth = texture(depthtex0, used_uv).r;
        return vec4(vec3(depth), 1.0);
    }

    vec4 sample_shadowtex() {
        #if DEBUG_BUFFER == 17
            return texture(shadowtex0, used_uv);
        #elif DEBUG_BUFFER == 18
            return texture(shadowtex1, used_uv);
        #else
            return vec4(0.0);
        #endif
    }

    vec4 sample_shadowcolor() {
        return vec4(texture(shadowcolor0, used_uv).rgb, 1.0);
    }

    void main() {
        color = texture(colortex0, uv);

        #if DEBUG_COVER_SCREEN == 0
            if (uv.x <= DEBUG_QUAD_WINDOW_LENGTH_RATIO && uv.y < DEBUG_QUAD_WINDOW_LENGTH_RATIO) { // scaling for rendering debug view in bottom left quadratn
                used_uv *= rcp(DEBUG_QUAD_WINDOW_LENGTH_RATIO);

                #if DEBUG_VIEW == 1
                    #if DEBUG_BUFFER <= 15
                        // -1 - +15.
                        color = sample_colortex();
                    #elif DEBUG_BUFFER <= 16
                        // 16.
                        color = vec4(interpolate_turbo(sample_depthtex().r), 1.0);
                    #elif DEBUG_BUFFER <= 18
                        // 17-18.
                        color = sample_shadowtex();
                    #elif DEBUG_BUFFER <= 19
                        // 19.
                        color = sample_shadowcolor();
                    #endif
                #endif
            }
        #endif

        #if DEBUG_COVER_SCREEN == 1
            #if DEBUG_VIEW == 1
                #if DEBUG_BUFFER <= 15
                    // -1 - +15.
                    color = sample_colortex();
                #elif DEBUG_BUFFER <= 16
                    // 16.
                    color = vec4(interpolate_turbo(sample_depthtex().r), 1.0);
                #elif DEBUG_BUFFER <= 18
                    // 17-18.
                    color = sample_shadowtex();
                #elif DEBUG_BUFFER <= 19
                    // 19.
                    color = sample_shadowcolor();
                #endif
            #endif
        #endif

        // sixthsurge's text renderer

        // vec4 normal_map_read, specular_map_read;
        // vec2 lightmap_uv, o_uv;
        // unpack_colortex1_read(texture(BUFFER_BITPACKED_DATA, uv), normal_map_read, specular_map_read, lightmap_uv, o_uv);

        // Material material;
        // init_material_unpacked_colortex_read(material);
        // vec3 frag_normal_world = material.normal;

        // float depth = texture(depthtex0, uv).r;
        // vec3 fragment_ndc_position = vec3(gl_FragCoord.xy / windowDimensions, depth) * 2.0 - 1.0;
        // vec3 fragment_view_position = ndc_to_view(fragment_ndc_position);
        // vec3 fragment_feet_position = view_to_feet(fragment_view_position);

        // // diffuse
        // vec3 fragment_world_position = feet_to_world(fragment_feet_position);
        // vec3 light_source_world_position = feet_to_world(view_to_feet(shadowLightPosition));
        // vec3 light_source_vector_world = normalize(light_source_world_position - fragment_world_position);
        // vec3 frag_view_vector_world = normalize(cameraPosition - fragment_world_position);

        // vec4 shadow_clip_position = shadow_view_to_shadow_clip(feet_to_shadow_view(fragment_feet_position));

        // vec3 sss = approximate_material_sss(material, fragment_world_position, light_source_vector_world, frag_view_vector_world);

        //     vec3 rsm_gi = texture(BUFFER_RSM_GI, uv).rgb;

        //     beginText(ivec2(gl_FragCoord.xy), ivec2(viewWidth / 2, viewHeight / 2)); // top left is easiest cause text can go offscreen
        //     printVec3(rsm_gi);
        //     // printFloat(sss);
        //     endText(color.rgb);
    }
#endif
