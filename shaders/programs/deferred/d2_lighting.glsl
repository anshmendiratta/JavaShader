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

    #include "/lib/settings.glsl"
    #include "/lib/buffers.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/noise.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/specular.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/color/conversions.glsl"

    void main() {
        // unpack colortex1 data
        vec4 normal_map_read, specular_map_read;
        vec2 lightmap_uv, o_uv;
        unpack_colortex1_read(texture(BUFFER_BITPACKED_DATA, uv), normal_map_read, specular_map_read, lightmap_uv, o_uv);

        color = texture(BUFFER_COLOR, uv);
        // do nothing if sky
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0 || renderStage == MC_RENDER_STAGE_CLOUDS) {
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material, normal_map_read, specular_map_read, uv);

        vec3 normal_world_space = material.normal;

        vec3 fragment_ndc_space_position = vec3(gl_FragCoord.xy / windowDimensions, depth) * 2.0 - 1.0;
        vec3 fragment_view_space_position = ndc_to_view(fragment_ndc_space_position);
        vec3 fragment_feet_space_position = view_to_feet(fragment_view_space_position);

        // shadows
        #if SHADOWS == 1
            vec3 shadow_view_space_position = (shadowModelView * vec4(fragment_feet_space_position, 1.0)).xyz;
            vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_view_space_position, 1.0);
            vec3 shadow = get_soft_shadow(shadow_clip_space_position, normal_world_space);
        #endif

        // diffuse
        vec3 fragment_world_space_position = feet_to_world(fragment_feet_space_position);
        vec3 light_source_world_space_position = feet_to_world(view_to_feet(shadowLightPosition));
        vec3 light_source_vector_world_space = normalize(light_source_world_space_position - fragment_world_space_position);
        float n_dot_l = compute_diffuse(light_source_vector_world_space, normal_world_space);

        // TODO: generalize `direct_lighting` def
        #if SPECULAR_MAPPING == 1
            vec3 view_vector_world_space = normalize(cameraPosition - fragment_world_space_position);
            // FIX: temporarily allowing access to fresnel here. privatize later. perhaps a general "get_lighting" func?
            vec3 fresnel;
            vec3 specular_light_factor = compute_specular(material, light_source_vector_world_space, view_vector_world_space, fresnel);
            vec3 diffuse_light_factor = n_dot_l * (1.0 - fresnel);

            vec3 direct_lighting = diffuse_light_factor + specular_light_factor;

            // TODO: this feels like a jank workaround for metals being naturally dim. find an all-encompassing way of handling metals/dielectrics.
            // NOTE: the level of "diffuse" lighting seems consistent with shrimple. ill trust it for now.
            if (material.is_metal) {
                // direct_lighting += fresnel; // FIX: this does NOT apply to shadowed regions. their albedo tinting is removed.
            }
        #else
            vec3 direct_lighting = vec3(n_dot_l);
        #endif

        // kinds of lighting contribution

        float BLOCKLIGHT_INTENSITY = lightmap_uv.x;
        vec3 blocklight = hsl_to_rgb(BLOCKLIGHT_INTENSITY_MULTIPLIER * rgb_to_hsl(BLOCKLIGHT_INTENSITY * BLOCKLIGHT_COLOR)); // x is blocklight

        float SKYLIGHT_INTENSITY = lightmap_uv.y;
        vec3 skylight = hsl_to_rgb(SKYLIGHT_INTENSITY_MULTIPLIER * rgb_to_hsl(SKYLIGHT_INTENSITY * SKYLIGHT_COLOR)); // y is skylight

        // TODO: change values this interpolates so sunrise/sunset/nighttime is better
        vec3 sunlight = compute_skylight_intensity_scalar(sunAngle) * direct_lighting * lightmap_uv.y * SUNLIGHT_COLOR; // multiply by lightmap_uv to fix some light leaks.

        vec3 direct_contribution = blocklight;
        #if SHADOWS == 1
            direct_contribution += sunlight * shadow;
        #else
            direct_contribution += sunlight;
        #endif
        vec3 indirect_contribution = skylight * compute_skylight_intensity_scalar(sunAngle);

        // lighting applications

        #if AMBIENT_OCCLUSION == 1
            // FIX: hand detection does not work?
            uint is_hand = texture(BUFFER_HAND_MASK, uv).r;
            float ao_factor = texture(BUFFER_SSAO, uv).r;
            if (is_hand == 0) {
                color.rgb *= vec3(ao_factor);
            }
        #endif

        color.rgb *= direct_contribution + indirect_contribution;

        #if SPECULAR_MAPPING == 1
            vec3 emission = EMISSION_STRENGTH * material.emissiveness * color.rgb; // bruh
            color.rgb += emission;
        #endif

        color.rgb = rgb_to_linear(color.rgb);
    }
#endif
