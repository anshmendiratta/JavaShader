struct Interface {
    vec2 uv;
};

#ifdef STAGE_VERTEX
    out Interface v;
    flat out ivec3 voxel_pos;

    #include "/include/utility/space_conversions.glsl"

    void main() {
        gl_Position = ftransform();

        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        vec3 vert_pos_shadow_view = (gl_ModelViewMatrix * gl_Vertex).xyz;
        vec3 vert_pos_feet = shadow_view_to_feet(vert_pos_shadow_view);
        vec3 pos_block_relative = vert_pos_feet + at_midBlock.xyz / 64. + fract(cameraPosition); // NOTE: understand what this does.
        voxel_pos = ivec3(pos_block_relative + VOXEL_RADIUS);
    }
#endif

#ifdef STAGE_FRAGMENT
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

    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/subsurface_scattering.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/dither.glsl"

    #if defined PHOTONICS
        #include "/photonics/photonics.glsl"

        uniform sampler2D radiosity_indirect;
    #endif

    in Interface v;
    flat in ivec3 voxel_pos;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    uniform usampler3D voxel_map;

    void main() {
        color = texture(colortex0, v.uv);
        color.rgb = rgb_to_linear(color.rgb); // NOTE: SHADING IS ONLY IN LINEAR COLOR SPACE !!!!!!!!!!!!!!!!
        float depth = texture(depthtex0, v.uv).r;
        if (depth == 1.) {
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material, v.uv);
        material.albedo = rgb_to_linear(material.albedo);

        vec3 frag_normal_world = material.normal;
        vec3 vertex_normal = texture(colortex3, v.uv).xyz * 2. - 1.;

        vec3 frag_pos_screen = vec3(v.uv, depth);
        vec3 frag_view_pos = screen_to_view(frag_pos_screen);
        vec3 frag_feet_pos = view_to_feet(frag_view_pos);

        vec3 frag_world_pos = feet_to_world(frag_feet_pos);
        vec3 light_source_vector_world = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
        vec3 n_dot_l = compute_diffuse(material, vertex_normal, light_source_vector_world);

        vec3 frag_view_vector_world = mat3(gbufferModelViewInverse) * normalize(-frag_view_pos);
        vec3 halfway_vector_world = normalize(frag_view_vector_world + light_source_vector_world);
        vec3 fresnel = material.is_metal ?
            _fresnel_rescaled_schlick(material, dot(frag_view_vector_world, halfway_vector_world)) :
            _fresnel_schlick(material, dot(light_source_vector_world, halfway_vector_world)); // L.H

        vec3 blocklight = hsl_to_rgb(vec3(1., 1., BLOCKLIGHT_INTENSITY) * rgb_to_hsl(material.lightmap_uv.x * BLOCKLIGHT_COLOR)); // x is blocklight
        vec3 skylight = hsl_to_rgb(vec3(1., 1., SKYLIGHT_INTENSITY) * rgb_to_hsl(material.lightmap_uv.y * SKYLIGHT_COLOR));
        vec3 sunlight = compute_sunlight_intensity_scalar(dayProgress) * material.lightmap_uv.y * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

        fix_hand_depth(depth);

        // --------------------
        //     Applications
        // --------------------

        vec3 shadow = vec3(step(0f, dot(vertex_normal, light_source_vector_world)));
        if (shadow != vec3(0.)) {
            vec4 shadow_clip_pos = shadow_view_to_shadow_clip(feet_to_shadow_view(frag_feet_pos));
            shadow *= compute_shadow(shadow_clip_pos, vertex_normal, material.lightmap_uv.y);
            #if CONTACT_SHADOWS == 1
                shadow *= compute_contact_shadow(frag_pos_screen);
            #endif
        }

        float ao = AMBIENT_OCCLUSION == 1 ?
            texture(BUFFER_SSAO, v.uv).r :
            1.;
        vec3 gi = RSM == 1 ?
            texture(colortex2, v.uv).rgb :
            vec3(0.);
        vec3 sss = SSS == 1 ?
            approximate_material_sss(material, frag_world_pos, light_source_vector_world, frag_view_vector_world) :
            vec3(0.);

        #if defined PHOTONICS
            skylight = texture(radiosity_indirect, v.uv).rgb;
            blocklight = sample_photonics_direct(v.uv);
        #endif

        color = vec4(blocklight, 1.);
        return;

        vec3 diffuse = material.albedo * sunlight * n_dot_l;
        vec3 specular = compute_specular(material, fresnel, light_source_vector_world, frag_view_vector_world);
        vec3 direct = material.is_metal ? fresnel * specular : mix(diffuse, specular, fresnel); // TODO: the mix between diffuse and specular is physically correct, but some metals still feel pretty dark
        vec3 indirect = material.albedo * (material.ao * ao * (skylight + blocklight) + sss) + gi;
        vec3 emission = material.albedo * EMISSION_STRENGTH * material.emissiveness;

        color.rgb = shadow * direct + indirect + emission;

        // if (clamp(voxel_pos, 0, VOXEL_RADIUS) == voxel_pos) {
        //     vec4 voxel_data = unpackUnorm4x8(texture(voxel_map, voxel_pos / vec3(VOXEL_AREA)).x);
        // color.rgb = voxel_data.www;
        // }
    }
#endif
