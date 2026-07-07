#ifdef STAGE_VERTEX
    in vec2 mc_Entity;
    in vec2 mc_midTexCoord;

    out vec2 uv;
    out vec2 lightmap_uv;
    out vec2 mcentity;
    out vec2 texture_bottom_left; // vec2(x_min, y_min).
    out vec2 single_tex_size; // vec2(x_range, y_range).
    out vec3 frag_water_displacement;
    out vec3 frag_normal_view;
    out vec3 frag_tangent_view;
    out vec4 glcolor;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/ids.glsl"

    // #include "/include/water/waves.glsl"

    #include "/include/utility/space_conversions.glsl"

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lightmap_uv = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        lightmap_uv = lightmap_uv / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from [0.033, 0.97] to [0.0, 1.0].

        glcolor = gl_Color;
        mcentity = mc_Entity;

        vec2 half_size = abs(uv - mc_midTexCoord);
        texture_bottom_left = mc_midTexCoord - half_size;
        single_tex_size = half_size * 2.0;

        frag_normal_view = normalize(gl_NormalMatrix * gl_Normal); // macro normal
        frag_tangent_view = at_tangent.w * normalize(gl_NormalMatrix * at_tangent.xyz);

        // #if WAVING_WATER == 1
            //     if (mc_Entity.x == ID_WATER) {
            //         vec3 view_space_position = (gbufferProjectionInverse * gl_Position).xyz;
            //         vec3 world_space_position = view_to_world(view_space_position);
            //         frag_water_displacement = compute_water_displacement(world_space_position);
            //         // world_space_position += frag_water_displacement;
            //         vec4 clip_space_position = view_to_clip(world_to_view(world_space_position));

            //         gl_Position = clip_space_position;

            //         vec3 frag_pos_world = view_to_world(clip_to_view(gl_Position));
            //         frag_normal_view = mat3(gbufferModelView) * compute_water_normal(frag_pos_world, frag_water_displacement);
            //     }
        // #endif
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;
    in vec2 lightmap_uv;
    in vec2 mcentity;
    in vec2 texture_bottom_left; // vec2(x_min, y_min).
    in vec2 single_tex_size; // vec2(x_range, y_range).
    in vec3 frag_tangent_view;
    in vec3 frag_normal_view;
    in vec3 frag_water_displacement;
    in vec4 glcolor;

    /* RENDERTARGETS: 0,1,3 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uvec4 bitpacked_data;
    layout(location = 2) out vec3 vertex_normal;

    #include "/include/uniforms.glsl"
    #include "/include/settings.glsl"
    #include "/include/buffers.glsl"
    #include "/include/ids.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/pbr/parallax.glsl"
    #include "/include/pbr/material.glsl"

    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/diffuse.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/bits.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        if (color.a < alphaTestRef) discard;
        color.rgb = rgb_to_linear(color.rgb);

        vertex_normal = (mat3(gbufferModelViewInverse) * frag_normal_view) * 0.5 + 0.5;

        // lighting

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 frag_position_screen = vec3(screen_uv, gl_FragCoord.z);
        vec3 frag_position_view = screen_to_view(frag_position_screen);
        vec3 frag_position_world = view_to_world(frag_position_view);
        vec3 frag_position_feet = world_to_feet(frag_position_world);

        // vec3 frag_bitangent_view = normalize(cross(frag_tangent_view, frag_normal_view));
        mat3 TBN_matrix = get_tbn_matrix(frag_normal_view);

        #if POM == 1
            vec3 view_direction_view = normalize(frag_position_view);
            vec3 view_direction_tangent = transpose(TBN_matrix) * view_direction_view;
            vec2 local_uv = atlas_uv_to_local(uv, texture_bottom_left, single_tex_size);
            vec2 pom_local_uv = pom_uv_transform(local_uv, view_direction_tangent, frag_position_view, TBN_matrix);
            vec2 pom_atlas_uv = local_uv_to_atlas(pom_local_uv, texture_bottom_left, single_tex_size);

            color = texture(gtexture, pom_atlas_uv) * glcolor;
        #endif

        #if POM == 1
            vec4 normal_map_read = texture(normals, pom_atlas_uv);
            vec4 specular_map_read = texture(specular, pom_atlas_uv);
        #else
            vec4 normal_map_read = texture(normals, uv);
            vec4 specular_map_read = texture(specular, uv);
        #endif

        normal_map_read.xy = normal_map_read.xy * 2.0 - 1.0;
        vec3 _frag_normal_normal = vec3(normal_map_read.xy, sqrt(1.0 - dot(normal_map_read.xy, normal_map_read.xy)));
        vec3 _frag_normal_view = TBN_matrix * _frag_normal_normal;
        vec3 frag_normal_world = normalize(mat3(gbufferModelViewInverse) * _frag_normal_view);
        vec2 frag_normal_octahedral_encoded = vector_encode_octahedral(frag_normal_world) * 0.5 + 0.5; // in [0, 1]^2

        bitpacked_data.r = packUnorm4x8(vec4(frag_normal_octahedral_encoded, normal_map_read.zw));
        bitpacked_data.g = packUnorm4x8(specular_map_read);
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        bitpacked_data.a = floatBitsToUint(mcentity.x);

        // forward rendering

        Material material;
        material.lightmap_uv = lightmap_uv;
        material.block_id = mcentity.x;
        material.normal = frag_normal_world; // world space
        init_material_raw_read(material, uv, TBN_matrix);

        // if (material.block_id == ID_WATER) color.a = 0.01;

        vec3 light_source_position_world = view_to_world(shadowLightPosition);
        vec3 light_source_vector_world = normalize(light_source_position_world - frag_position_world);
        vec3 frag_view_vector_world = normalize(cameraPosition - frag_position_world);
        vec3 halfway_vector_world = normalize(light_source_vector_world + frag_view_vector_world);

        // fresnel. cant be metal
        vec3 fresnel = (material.block_id == ID_WATER) ?
            _fresnel_schlick(material, dot(material.normal, frag_view_vector_world)) :
            _fresnel_schlick(material, dot(halfway_vector_world, frag_view_vector_world));

        #if SHADOWS == 1
            vec4 shadow_clip_position = shadow_view_to_shadow_clip(feet_to_shadow_view(frag_position_feet));
            vec3 shadow = _get_soft_shadow(shadow_clip_position, frag_normal_world, material.lightmap_uv.y);
        #else
            vec3 shadow = vec3(1.0);
        #endif
        #if AMBIENT_OCCLUSION == 1
            float ao_factor = texture(BUFFER_SSAO, uv).r;
        #else
            float ao_factor = 1.0;
        #endif

        vec3 n_dot_l = compute_diffuse(material, light_source_vector_world);

        vec3 blocklight = hsl_to_rgb(vec3(1., 1., BLOCKLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(lightmap_uv.x * BLOCKLIGHT_COLOR)); // x is blocklight
        vec3 skylight = hsl_to_rgb(vec3(1., 1., SKYLIGHT_INTENSITY_MULTIPLIER) * rgb_to_hsl(lightmap_uv.y * SKYLIGHT_COLOR));
        vec3 sunlight = compute_skylight_intensity_scalar(dayProgress) * lightmap_uv.y * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

        vec3 diffuse_light_factor = ao_factor * n_dot_l * sunlight; // ao added here so darkening is more visible
        vec3 specular_light_factor = compute_specular(material, fresnel, light_source_vector_world, frag_view_vector_world);

        vec3 direct_lighting = mix(diffuse_light_factor, specular_light_factor, fresnel) + blocklight;
        vec3 indirect_lighting = skylight;
        vec3 emission = EMISSION_STRENGTH * material.emissiveness * material.albedo; // bruh. i dont remember why i added this comment

        color.rgb *= shadow * direct_lighting + indirect_lighting + emission;
    }
#endif
