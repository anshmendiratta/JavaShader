#ifdef STAGE_VERTEX
    in vec2 mc_Entity;
    in vec2 mc_midTexCoord;
    in vec4 at_tangent;

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

    #include "/include/water/waves.glsl"

    #include "/include/utility/space_conversions.glsl"

    void main() {
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        gl_Position = ftransform();
        glcolor = gl_Color;
        mcentity = mc_Entity;

        vec2 half_size = abs(uv - mc_midTexCoord);
        texture_bottom_left = mc_midTexCoord - half_size;
        single_tex_size = half_size * 2.0;

        lightmap_uv = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        lightmap_uv = lightmap_uv / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from [0.033, 0.97] to [0.0, 1.0].

        frag_normal_view = normalize(gl_NormalMatrix * gl_Normal);
        frag_tangent_view = normalize(at_tangent.w * (gl_NormalMatrix * at_tangent.xyz));

        #if WAVING_WATER == 1
            if (mc_Entity.x == ID_WATER) {
                vec3 view_space_position = (gbufferProjectionInverse * gl_Position).xyz;
                vec3 world_space_position = feet_to_world(view_to_feet(view_space_position));
                frag_water_displacement = compute_water_displacement(world_space_position);
                world_space_position += frag_water_displacement;
                vec4 clip_space_position = view_to_clip(feet_to_view(world_to_feet(world_space_position)));

                gl_Position = clip_space_position;
            }
        #endif
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

    /* RENDERTARGETS: 0,1 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uvec4 bitpacked_data;

    #include "/include/uniforms.glsl"

    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/bits.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/pbr/parallax.glsl"

    #include "/include/color/conversions.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        if (color.a < alphaTestRef) discard;

        color.rgb = rgb_to_linear(color.rgb);

        float frag_depth = texture(depthtex0, uv).r;
        if (frag_depth == 1.0) return; // skip something idk

        // lighting

        // FIX: broken

        vec3 frag_position_screen = vec3(uv, frag_depth);
        vec3 frag_position_view = screen_to_view(frag_position_screen);
        vec3 frag_position_world = view_to_world(frag_position_view);

        vec3 wave_normal = normalize(compute_water_normal(frag_position_world, frag_water_displacement));
        // vec3 wave_normal = vec3(0.0, abs(sin(frag_position_world.z)), 0.0);

        float n_dot_l = clamp01(dot(wave_normal, vec3(0.0, 1.0, 0.0)));

        // color.rgb *= n_dot_l;

        vec3 frag_bitangent_view = normalize(cross(frag_tangent_view, frag_normal_view));
        mat3 TBN_matrix = mat3(frag_tangent_view, frag_bitangent_view, frag_normal_view);

        #if POM == 1
            vec3 fragment_ndc_position = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z) * 2.0 - 1.0;
            vec3 fragment_view_position = ndc_to_view(fragment_ndc_position);
            vec3 view_direction_view = normalize(fragment_view_position);
            vec3 view_direction_tangent = transpose(TBN_matrix) * view_direction_view;
            vec2 local_uv = atlas_uv_to_local(uv, texture_bottom_left, single_tex_size);
            vec2 pom_local_uv = pom_uv_transform(local_uv, view_direction_tangent, fragment_view_position, TBN_matrix);
            vec2 pom_atlas_uv = local_uv_to_atlas(pom_local_uv, texture_bottom_left, single_tex_size);

            color = texture(gtexture, pom_atlas_uv) * glcolor;
        #endif

        #if POM == 1
            vec4 normal_map_read = texture(normals, pom_atlas_uv, 0);
            vec4 specular_map_read = texture(specular, pom_atlas_uv, 0);
        #else
            vec4 normal_map_read = texture(normals, uv, 0);
            vec4 specular_map_read = texture(specular, uv, 0);
        #endif

        vec3 frag_normal_world = normalize(mat3(gbufferModelViewInverse) * frag_normal_view);
        vec2 frag_normal_octahedral_encoded = vector_encode_octahedral(frag_normal_world) * 0.5 + 0.5; // in [0, 1]^2

        bitpacked_data.r = packUnorm4x8(vec4(frag_normal_octahedral_encoded, normal_map_read.zw));
        bitpacked_data.g = packUnorm4x8(specular_map_read);
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        bitpacked_data.a = uint(mcentity.x);
    }
#endif
