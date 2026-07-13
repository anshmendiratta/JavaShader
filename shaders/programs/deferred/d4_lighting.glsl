#ifdef STAGE_VERTEX
    out vec2 uv;

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

    #include "/include/sky/intensity.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/dither.glsl"

    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/subsurface_scattering.glsl"

    // #if defined PHOTONICS
        //     #include "/photonics/photonics.glsl"
        //     uniform sampler2D radiosity_indirect;
    // #endif

    void main() {
        color = texture(colortex0, uv);
        color.rgb = rgb_to_linear(color.rgb); // NOTE: SHADING IS ONLY IN LINEAR COLOR SPACE !!!!!!!!!!!!!!!!
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.) {
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material);

        vec3 frag_normal_world = material.normal;
        vec3 vertex_normal = texture(colortex3, uv).xyz * 2. - 1.;

        vec3 fragment_ndc_position = vec3(gl_FragCoord.xy / windowDimensions, depth) * 2. - 1.;
        vec3 fragment_view_position = ndc_to_view(fragment_ndc_position);
        vec3 fragment_feet_position = view_to_feet(fragment_view_position);

        // diffuse
        vec3 fragment_world_position = feet_to_world(fragment_feet_position);
        vec3 light_source_world_position = view_to_world(shadowLightPosition);
        vec3 light_source_vector_world = normalize(light_source_world_position - fragment_world_position);
        vec3 n_dot_l = compute_diffuse(material, vertex_normal, light_source_vector_world);

        // fresnel
        vec3 frag_view_vector_world = normalize(cameraPosition - fragment_world_position);
        vec3 halfway_vector_world = normalize(frag_view_vector_world + light_source_vector_world);
        vec3 fresnel = material.is_metal ?
            _fresnel_rescaled_schlick(material, dot(frag_view_vector_world, halfway_vector_world)) :
            _fresnel_schlick(material, dot(light_source_vector_world, halfway_vector_world)); // L.H

        // specular
        vec3 specular = compute_specular(material, fresnel, light_source_vector_world, frag_view_vector_world);

        vec3 blocklight = hsl_to_rgb(vec3(1., 1., BLOCKLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(material.lightmap_uv.x * BLOCKLIGHT_COLOR)); // x is blocklight
        vec3 skylight = hsl_to_rgb(vec3(1., 1., SKYLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(material.lightmap_uv.y * SKYLIGHT_COLOR));
        vec3 sunlight = compute_skylight_intensity_scalar(dayProgress) * material.lightmap_uv.y * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;

        // blocklight += sample_photonics_direct(screen_uv);

        // --------------------
        //     Applications
        // --------------------

        #if SHADOWS == 1
            vec4 shadow_clip_position = shadow_view_to_shadow_clip(feet_to_shadow_view(fragment_feet_position));
            vec3 shadow = _get_soft_shadow(shadow_clip_position, vertex_normal, material.lightmap_uv.y);
        #else
            vec3 shadow = vec3(1.);
        #endif

        #if RSM == 1
            vec3 gi = texture(colortex2, uv).rgb;
        #else
            vec3 gi = vec3(0.);
        #endif

        // #if defined PHOTONICS
            //     gi = texture(radiosity_indirect, gl_FragCoord.xy / windowDimensions).rgb;
        // #endif

        #if AMBIENT_OCCLUSION == 1
            float ao = texture(BUFFER_SSAO, uv).r;
            if (fragment_is_translucent(uv)) ao = 1.;
        #else
            float ao = 1.;
        #endif

        #if SSS == 1
            vec3 sss = approximate_material_sss(material, fragment_world_position, light_source_vector_world, frag_view_vector_world);
        #else
            vec3 sss = vec3(0.);
        #endif

        vec3 diffuse = sunlight * n_dot_l;
        // TODO: the mix between diffuse and specular is physically correct, but some metals still feel pretty dark
        vec3 direct = material.is_metal ? shadow * fresnel * specular : mix(diffuse, specular, fresnel);
        vec3 indirect = ao * skylight + sss + gi + blocklight;
        vec3 emission = EMISSION_STRENGTH * material.emissiveness * material.albedo;

        color.rgb *= fragment_is_hand(uv) ?
            vec3(1.) :
            shadow * direct + indirect + emission;
        // gi;
    }
#endif
