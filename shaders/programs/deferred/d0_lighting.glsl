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

    #include "/lib/settings.glsl"

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
        unpack_colortex1_read(texture(colortex1, uv), normal_map_read, specular_map_read, lightmap_uv, o_uv);

        // do nothing if sky
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0) {
            return;
        }

        color = texture(colortex0, uv);

        Material material;
        init_material_unpacked_colortex_read(material, normal_map_read, specular_map_read);

        vec3 normal_world_space = material.normal;

        // shadows
        vec3 fragment_ndc_space_position = vec3(uv.xy, depth) * 2.0 - 1.0;
        vec3 fragment_view_space_position = ndc_to_view(fragment_ndc_space_position);
        vec3 fragment_feet_space_position = view_to_feet(fragment_view_space_position);
        vec3 shadow_view_space_position = (shadowModelView * vec4(fragment_feet_space_position, 1.0)).xyz;
        vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_view_space_position, 1.0);
        vec3 shadow = get_soft_shadow(shadow_clip_space_position, normal_world_space);

        // diffuse
        vec3 fragment_world_space_position = feet_to_world(fragment_feet_space_position);
        vec3 light_source_world_space_position = feet_to_world(view_to_feet(shadowLightPosition));
        vec3 light_source_direction_world_space = normalize(light_source_world_space_position - fragment_world_space_position);
        float n_dot_l = compute_diffuse(light_source_direction_world_space, normal_world_space);

        float light_brightness = n_dot_l;

        // TODO: somehow this doesnt work with h.v but does with r.v
        #if SPECULAR_MAPPING == 1
            float perceptual_roughness = material.nonlinear_smoothness;
            float roughness = pow(1.0 - perceptual_roughness, 2.0);
            float smoothness = 1.0 - roughness;

            // https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model
            vec3 view_vector_world_space = fragment_world_space_position - cameraPosition;
            float h_dot_v = compute_specular(view_vector_world_space, light_source_direction_world_space, normal_world_space);
            float shininess = smoothness * 200.0 + 1.0; // alpha
            float specular_light_factor = smoothness * pow(h_dot_v, 4.0 * shininess);
            float diffuse_light_factor = roughness * n_dot_l;
            light_brightness = diffuse_light_factor + specular_light_factor;
        #endif

        // kinds of lighting contribution

        float BLOCKLIGHT_INTENSITY = lightmap_uv.x;
        vec3 blocklight = BLOCKLIGHT_INTENSITY * BLOCKLIGHT_COLOR; // x is blocklight

        float SKYLIGHT_INTENSITY = lightmap_uv.y;
        vec3 skylight = SKYLIGHT_INTENSITY * SKYLIGHT_COLOR; // y is skylight

        float ssao_factor = texture(colortex4, uv).r;
        vec3 ambient = vec3(
                AMBIENT_INTENSITY * ssao_factor
            );

        // TODO: vary sunlight intensity by time of day.
        vec3 sunlight = light_brightness * shadow * lightmap_uv.y * SUNLIGHT_COLOR; // multiply by lightmap_uv to fix some light leaks.

        // color.rgb *= blocklight + skylight + sunlight + ambient;
        // color.rgb = rgb_to_linear(color.rgb);
        color.rgb = vec3(1.0);
    }
#endif
