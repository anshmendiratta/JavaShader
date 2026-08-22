struct Interface {
    vec2 uv;
    vec3 voxel_pos;
};

layout(r32ui) uniform uimage3D voxel_map;
uniform sampler3D floodfill_map;

#ifdef STAGE_VERTEX
    out Interface v;

    #include "/include/uniforms.glsl"

    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/voxelization.glsl"

    void main() {
        gl_Position = ftransform();
        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"
    #include "/include/buffers.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/debug_text.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/post/taa.glsl"

    #include "/include/color/grading.glsl"
    #include "/include/color/conversions.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"
    #include "/include/pbr/light.glsl"

    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/subsurface_scattering.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/voxelization.glsl"

    #if defined PHOTONICS
        // #include "/photonics/photonics.glsl"

        uniform sampler2D radiosity_indirect;
    #endif

    in Interface v;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    void main() {
        vec2 uv = v.uv - dot(
                    vec2(dFdx(v.uv).x, dFdy(v.uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);

        color = texture(colortex0, uv);
        color.rgb = SRGB_TO_ACESCG * rgb_to_linear(color.rgb); // NOTE: SHADING IS ONLY IN LINEAR COLOR SPACE !!!!!!!!!!!!!!!!

        float depth = texture(depthtex0, uv).r;
        if (depth == 1.) {
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material, uv);
        material.albedo = SRGB_TO_ACESCG * rgb_to_linear(material.albedo);

        vec3 frag_normal_world = material.normal;
        vec3 vertex_normal = texture(colortex3, uv).xyz * 2. - 1.;

        vec3 frag_pos_screen = vec3(uv, depth);
        vec3 frag_view_pos = screen_to_view(frag_pos_screen);
        vec3 frag_feet_pos = view_to_feet(frag_view_pos);

        vec3 frag_world_pos = feet_to_world(frag_feet_pos);
        vec3 light_source_vector_world = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
        vec3 frag_view_vector_world = mat3(gbufferModelViewInverse) * normalize(-frag_view_pos);
        vec3 n_dot_l = compute_diffuse(material, vertex_normal, light_source_vector_world, frag_view_vector_world);

        vec3 halfway_vector_world = normalize(frag_view_vector_world + light_source_vector_world);
        vec3 fresnel = material.is_metal ?
            _fresnel_rescaled_schlick(material, dot(frag_view_vector_world, halfway_vector_world)) :
            _fresnel_schlick(material, dot(light_source_vector_world, halfway_vector_world)); // L.H

        float sun_moon_intensity = compute_direct_light_scalar(dayProgress);

        vec3 skylight = sun_moon_intensity * pow4(material.lightmap_uv.y) * (SRGB_TO_ACESCG * rgb_to_linear(SKYLIGHT_COLOR));
        vec3 sunlight = sun_moon_intensity * get_sunlight_color(max0(frag_view_vector_world.y)); // lightmap_uv.y fixes some light leaks

        vec3 voxel_pos = feet_to_voxel_space(frag_feet_pos);
        vec3 voxel_pos_sample = clamp01((voxel_pos - 0.5 * vertex_normal) / vec3(VOXEL_VOLUME_SIZE));
        // vec3 blocklight = !is_inside_voxel_radius(voxel_pos) ?
        //     sqrt(texture(floodfill_map, voxel_pos_sample).rgb) :
        //     brighten_rgb(material.lightmap_uv.x * BLOCKLIGHT_COLOR, BLOCKLIGHT_INTENSITY); // x is blocklight
        vec3 blocklight = vec3(0.);

        fix_hand_depth(depth);

        // --------------------
        //     Applications
        // --------------------

        vec3 shadow = vec3(step(0f, dot(vertex_normal, light_source_vector_world)));
        shadow *= (shadow != vec3(0.)) && (SHADOWS == 1) ?
            compute_shadow(frag_world_pos, vertex_normal, material.lightmap_uv.y) :
            vec3(1.);
        shadow *= CONTACT_SHADOWS == 1 ?
            compute_contact_shadow(frag_pos_screen) :
            vec3(1.);

        float ao = AMBIENT_OCCLUSION == 1 ?
            texture(BUFFER_SSAO, uv).r :
            1.;
        vec3 gi = RSM == 1 ?
            texture(colortex2, uv).rgb :
            vec3(0.);
        vec3 sss = SSS == 1 && SHADOWS == 1 ?
            sun_moon_intensity * approximate_material_sss(material, frag_world_pos, light_source_vector_world, frag_view_vector_world) :
            vec3(0.);

        #if defined PHOTONICS && PHOTONICS_ENABLED
            skylight = texture(radiosity_indirect, uv).rgb;
            blocklight = sample_photonics_direct(uv);
        #endif

        vec3 diffuse = material.albedo * sunlight * n_dot_l;
        vec3 specular = compute_specular(material, fresnel, light_source_vector_world, frag_view_vector_world);

        // TODO: the mix between diffuse and specular is physically correct, but some metals still feel pretty dark
        vec3 direct = material.is_metal ?
            fresnel * specular :
            mix(diffuse, specular, fresnel);
        vec3 indirect = material.albedo * material.ao * ao * (skylight + blocklight + sss) + gi;
        vec3 emission = brighten_rgb(material.albedo * material.emissiveness, EMISSION_STRENGTH);

        color.rgb = inverse(SRGB_TO_ACESCG) * (shadow * direct + indirect + emission);
    }
#endif
