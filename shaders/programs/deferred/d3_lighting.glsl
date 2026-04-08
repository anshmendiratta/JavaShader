#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;
    in vec2 mc_Entity;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/settings.glsl"
    #include "/include/buffers.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/math/convenience.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/noise.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/subsurface_scattering.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/color/conversions.glsl"

    void main() {
        // unpack colortex1 data
        vec4 normal_map_read, specular_map_read;
        vec2 lightmap_uv, o_uv;
        unpack_colortex1_read(texture(BUFFER_BITPACKED_DATA, uv), normal_map_read, specular_map_read, lightmap_uv, o_uv);

        color = texture(BUFFER_COLOR, uv);
        color.rgb = rgb_to_linear(color.rgb); // NOTE: SHADING IS ONLY IN LINEAR COLOR SPACE !!!!!!!!!!!!!!!!
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0) { // don't shade sky
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material, normal_map_read, specular_map_read, uv);
        vec3 frag_normal_world = material.normal;

        vec3 fragment_ndc_position = vec3(gl_FragCoord.xy / windowDimensions, depth) * 2.0 - 1.0;
        vec3 fragment_view_position = ndc_to_view(fragment_ndc_position);
        vec3 fragment_feet_position = view_to_feet(fragment_view_position);

        // diffuse
        vec3 fragment_world_position = feet_to_world(fragment_feet_position);
        vec3 light_source_world_position = feet_to_world(view_to_feet(shadowLightPosition));
        vec3 light_source_vector_world = normalize(light_source_world_position - fragment_world_position);
        vec3 n_dot_l = compute_diffuse(material, light_source_vector_world);
        // specular
        vec3 frag_view_vector_world = normalize(cameraPosition - fragment_world_position);
        vec3 fresnel;
        vec3 specular = max0(compute_specular(material, light_source_vector_world, frag_view_vector_world, fresnel));

        vec3 blocklight = hsl_to_rgb(vec3(1., 1., BLOCKLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(lightmap_uv.x * BLOCKLIGHT_COLOR)); // x is blocklight
        vec3 skylight = hsl_to_rgb(vec3(1., 1., SKYLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(lightmap_uv.y * SKYLIGHT_COLOR));
        vec3 sunlight = compute_skylight_intensity_scalar(dayProgress) * lightmap_uv.y * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

        // lighting applications

        // shadows
        #if SHADOWS == 1
            vec3 shadow_view_position = (shadowModelView * vec4(fragment_feet_position, 1.0)).xyz;
            vec4 shadow_clip_position = shadowProjection * vec4(shadow_view_position, 1.0);
            vec3 shadow = _get_soft_shadow(shadow_clip_position, frag_normal_world, lightmap_uv.y);
        #else
            vec3 shadow = vec3(1.0);
        #endif
        #if RSM == 1
            vec3 rsm_gi = texture(BUFFER_RSM_GI, uv).rgb;
        #else
            vec3 rsm_gi = vec3(0.0);
        #endif
        #if AMBIENT_OCCLUSION == 1
            float ao_factor = texture(BUFFER_SSAO, uv).r;
        #else
            float ao_factor = 1.0;
        #endif

        vec3 sss = approximate_material_sss(material, fragment_world_position, light_source_vector_world, -frag_view_vector_world);

        vec3 diffuse_light_factor = n_dot_l * (blocklight + sunlight) + sss;
        // FIX: temporarily allowing access to fresnel here. privatize later. perhaps a general "get_lighting" func?
        // NOTE: the level of "diffuse" lighting seems consistent with shrimple. ill trust it for now.
        // NOTE: this is apparently "correct" but the lighting wth specular mapping is still pretty meh.
        vec3 direct_lighting = (fresnel * specular + int(!material.is_metal) * (1.0 - fresnel) * diffuse_light_factor) * shadow;
        vec3 indirect_lighting = (rsm_gi + skylight) * ao_factor;
        vec3 emission = EMISSION_STRENGTH * material.emissiveness * material.albedo; // bruh. i dont remember why i added this comment

        bool is_hand = fragment_is_hand(uv);

        color.rgb *= int(!is_hand) * (direct_lighting + indirect_lighting + emission); // do nothing if hand. FIX: hand is fully black
    }
#endif
