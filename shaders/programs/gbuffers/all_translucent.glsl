layout(r32ui) uniform uimage3D voxel_map;
uniform sampler3D floodfill_map;

#ifdef STAGE_VERTEX
    flat out uint block_id;

    out vec2 uv;
    out vec2 lightmap_uv;

    out vec2 texture_bottom_left; // vec2(x_min, y_min).
    out vec2 single_tex_size; // vec2(x_range, y_range).

    out vec3 frag_water_displacement;
    out vec3 frag_normal_view;
    out vec3 frag_tangent_view;

    out vec4 glcolor;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/ids.glsl"

    #include "/include/post/taa.glsl"

    #include "/include/utility/coordinates.glsl"

    void main() {
        gl_Position = ftransform();
        #if TAA == 1
            gl_Position.xy += 2. * taa_jitter * gl_Position.w;
        #endif

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lightmap_uv = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        lightmap_uv = lightmap_uv / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from[0.033 , 0.97 ] to[0.0 , 1.0 ] .

        block_id = uint(mc_Entity.x);

        vec2 half_size = abs(uv - mc_midTexCoord);
        texture_bottom_left = mc_midTexCoord - half_size;
        single_tex_size = half_size * 2.0;

        frag_normal_view = normalize(gl_NormalMatrix * gl_Normal); // macro normal
        frag_tangent_view = at_tangent.w * normalize(gl_NormalMatrix * at_tangent.xyz);

        glcolor = gl_Color;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;
    in vec2 lightmap_uv;
    flat in uint block_id;

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

    #include "/include/color/grading.glsl"

    #include "/include/pbr/parallax.glsl"
    #include "/include/pbr/material.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/shadows/compute.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/bits.glsl"
    #include "/include/utility/voxelization.glsl"

    #include "/include/lighting/specular.glsl"
    #include "/include/lighting/diffuse.glsl"
    #include "/include/lighting/subsurface_scattering.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        if (block_id == ID_WATER) color.a = 0.01;
        if (color.a < alphaTestRef) discard;

        // --------------
        //    Lighting
        // --------------

        #if WHITEWORLD == 1
            color.rgb = vec3(0.5);
        #endif

        color.rgb = rgb_to_linear(color.rgb);

        vertex_normal = normalize(mat3(gbufferModelViewInverse) * frag_normal_view);

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 frag_pos_screen = vec3(screen_uv, gl_FragCoord.z);
        vec3 frag_pos_view = screen_to_view(frag_pos_screen);
        vec3 frag_pos_world = view_to_world(frag_pos_view);
        vec3 frag_pos_feet = world_to_feet(frag_pos_world);

        mat3 TBN_matrix = get_tbn_matrix(frag_normal_view);

        #if POM == 1
            vec3 view_direction_view = normalize(frag_pos_view);
            vec3 view_direction_tangent = transpose(TBN_matrix) * view_direction_view;
            vec2 local_uv = atlas_uv_to_local(uv, texture_bottom_left, single_tex_size);
            vec2 pom_local_uv = pom_uv_transform(local_uv, view_direction_tangent, frag_pos_view, TBN_matrix);
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

        vec3 frag_normal_world;
        if (block_id != ID_WATER) {
            normal_map_read.xy = normal_map_read.xy * 2.0 - 1.0;
            vec3 _frag_normal_normal = vec3(normal_map_read.xy, sqrt(1.0 - dot(normal_map_read.xy, normal_map_read.xy)));
            vec3 _frag_normal_view = TBN_matrix * _frag_normal_normal;
            frag_normal_world = normalize(mat3(gbufferModelViewInverse) * _frag_normal_view);
        } else {
            vec3 frag_pos_screen = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z);
            vec3 frag_pos_view = screen_to_view(frag_pos_screen);
            vec3 frag_pos_world = view_to_world(frag_pos_view);
            frag_normal_world = abs(compute_water_normal(frag_pos_world));
        }
        vec2 frag_normal_octahedral_encoded = vector_encode_octahedral(frag_normal_world) * 0.5 + 0.5; // in [ 0, 1 ] ^ 2

        bitpacked_data.r = packUnorm4x8(vec4(frag_normal_octahedral_encoded, normal_map_read.zw));
        bitpacked_data.g = packUnorm4x8(specular_map_read);
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        bitpacked_data.a = block_id;

        // -----------------------
        //    Forward rendering
        // -----------------------

        Material material;
        material.albedo = rgb_to_linear(color.rgb);
        material.lightmap_uv = lightmap_uv;
        material.block_id = block_id;
        material.normal = frag_normal_world;
        init_material_raw_read(material, uv, TBN_matrix);

        vec3 light_source_position_world = view_to_world(shadowLightPosition);
        vec3 light_source_vector_world = normalize(light_source_position_world - frag_pos_world);
        vec3 frag_view_vector_world = normalize(cameraPosition - frag_pos_world);
        vec3 halfway_vector_world = normalize(light_source_vector_world + frag_view_vector_world);

        // fresnel. cant be metal
        vec3 fresnel = material.block_id == ID_WATER ?
            _fresnel_schlick(material, dot(material.normal, frag_view_vector_world)) :
            _fresnel_rescaled_schlick(material, dot(halfway_vector_world, light_source_vector_world));

        vec3 n_dot_l = compute_diffuse(material, vertex_normal, light_source_vector_world, frag_view_vector_world);

        float sun_moon_intensity = compute_direct_light_scalar(dayProgress);

        vec3 skylight = sun_moon_intensity * material.lightmap_uv.y * SKYLIGHT_COLOR;
        vec3 sunlight = sun_moon_intensity * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

        vec3 voxel_pos = feet_to_voxel_space(frag_pos_feet);
        vec3 voxel_pos_sample = clamp01((voxel_pos - 0.5 * vertex_normal) / vec3(VOXEL_VOLUME_SIZE));
        vec3 blocklight = is_inside_voxel_radius(voxel_pos) ?
            vec3(0.) :
        // sqrt(texture(floodfill_map, voxel_pos_sample).rgb) :
            brighten_rgb(material.lightmap_uv.x * BLOCKLIGHT_COLOR, BLOCKLIGHT_INTENSITY); // x is blocklight

        // --------------------
        //     Applications
        // --------------------

        vec3 shadow = vec3(step(0f, dot(vertex_normal, light_source_vector_world)));
        shadow *= (shadow != vec3(0.)) && (SHADOWS == 1) ?
            compute_shadow(frag_pos_world, vertex_normal, material.lightmap_uv.y) :
            vec3(1.);
        shadow *= CONTACT_SHADOWS == 1 ?
            compute_contact_shadow(frag_pos_screen) :
            vec3(1.);

        vec3 gi = RSM == 1 ?
            texture(colortex2, uv).rgb :
            vec3(0.);
        vec3 sss = SSS == 1 && SHADOWS == 1 ?
            sun_moon_intensity * approximate_material_sss(material, frag_pos_world, light_source_vector_world, frag_view_vector_world) :
            vec3(0.);

        vec3 diffuse = color.rgb * n_dot_l * sunlight;
        vec3 specular = compute_specular(material, fresnel, light_source_vector_world, frag_view_vector_world);

        vec3 direct = material.block_id == ID_WATER ?
            specular :
            mix(diffuse, specular, fresnel);
        vec3 indirect = material.albedo * material.ao * (skylight + blocklight + sss) + gi;
        vec3 emission = brighten_rgb(material.emissiveness * material.albedo, EMISSION_STRENGTH);

        color.rgb = shadow * direct + indirect + emission;

        vertex_normal = vertex_normal * 0.5 + 0.5;
    }
#endif
