#ifdef STAGE_VERTEX
    in vec2 mc_midTexCoord;
    in vec2 mc_Entity;
    in vec4 at_tangent;

    out vec2 uv;
    out vec2 lightmap_uv;
    out vec2 texture_bottom_left; // vec2(x_min, y_min).
    out vec2 single_tex_size; // vec2(x_range, y_range).
    out vec3 frag_normal_view;
    out vec3 frag_tangent_view;
    out vec4 glcolor;

    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"
    #include "/include/ids.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/noise.glsl"

    #include "/include/pbr/material.glsl"

    void main() {
        gl_Position = ftransform();
        glcolor = gl_Color;

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        vec2 half_size = abs(uv - mc_midTexCoord);
        texture_bottom_left = mc_midTexCoord - half_size;
        single_tex_size = half_size * 2.0;

        lightmap_uv = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        lightmap_uv = lightmap_uv / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from [0.033, 0.97] to [0.0, 1.0].

        frag_normal_view = mc_Entity.x == 10000.0 ? gl_NormalMatrix * vec3(0.0, 1.0, 0.0) : normalize(gl_NormalMatrix * gl_Normal);
        frag_tangent_view = normalize(at_tangent.w * (gl_NormalMatrix * at_tangent.xyz));

        #if WAVING_FOLIAGE == 1
            // Waving foliage.
            // TODO: foliage "jitters" when the camera does.
            vec3 vertex_view_position = (gbufferProjectionInverse * gl_Position).xyz;
            vec3 vertex_player_position = (gbufferModelViewInverse * vec4(vertex_view_position, 1.0)).xyz;
            vec3 vertex_world_position = vertex_player_position + cameraPosition;
            vec3 vertex_offset_world = vec3(0.0, 0.0, 0.0);

            // TODO: Make look nicer.
            if (mc_Entity.x == ID_ROOTED_FOLIAGE) { // Rooted foliage.
                // TOOD: Figure out why this check doesn't just move one half of the block.
                if (uv.y < mc_midTexCoord.y) {
                    vertex_offset_world = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_position.xy / 3.0),
                                0.0,
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_position.zx / 3.0)
                            );
                }
            } else if (mc_Entity.x == ID_FREE_FOLIAGE) { // Leaves.
                vertex_offset_world = FOLIAGE_WAVE_AMPLITUDE * vec3(
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_position.xy),
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_position.yz),
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_position.zx)
                        );
            }

            vec3 vertex_offset_view = mat3(gbufferModelView) * vertex_offset_world;
            vertex_view_position += vertex_offset_view;
            gl_Position = gbufferProjection * vec4(vertex_view_position, 1.0);
        #endif
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec4 glcolor;
    in vec3 frag_tangent_view;
    in vec3 frag_normal_view;
    in vec2 lightmap_uv;
    in vec2 uv;
    in vec2 texture_bottom_left; // vec2(x_min, y_min).
    in vec2 single_tex_size; // vec2(x_range, y_range).

    /* RENDERTARGETS: 0,1 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uvec4 bitpacked_data; // normal map (4x u8 / 2x u16), specular map (4x u8), lightmap uv (2x half), uv (2x half)

    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/pbr/textures.glsl"
    #if POM == 1
        #include "/include/pbr/parallax.glsl"
    #endif

    void main() {
        color = texture(gtexture, uv) * glcolor;
        if (color.a < alphaTestRef) discard;

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

        // packing

        #if POM == 1
            vec4 normal_map_read = texture(normals, pom_atlas_uv, 0);
            vec4 specular_map_read = texture(specular, pom_atlas_uv, 0);
        #else
            vec4 normal_map_read = texture(normals, uv, 0);
            vec4 specular_map_read = texture(specular, uv, 0);
        #endif

        normal_map_read.xy = normal_map_read.xy * 2.0 - 1.0;
        vec3 frag_normal_normal = vec3(normal_map_read.xy, sqrt(1.0 - dot(normal_map_read.xy, normal_map_read.xy)));
        vec3 frag_normal_view = TBN_matrix * frag_normal_normal;
        vec3 frag_normal_world = normalize(mat3(gbufferModelViewInverse) * frag_normal_view);
        vec2 frag_normal_octahedral_encoded = vector_encode_octahedral(frag_normal_world) * 0.5 + 0.5; // in [0, 1]^2

        bitpacked_data.r = packUnorm4x8(vec4(frag_normal_octahedral_encoded, normal_map_read.zw));
        bitpacked_data.g = packUnorm4x8(specular_map_read);
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        #if POM == 1
            bitpacked_data.a = packUnorm2x16(pom_atlas_uv);
        #endif

        // FIX: for some reason particles need further gamma correction? maybe try and find a way to avoid this line
        if (renderStage == MC_RENDER_STAGE_PARTICLES) color.rgb = rgb_to_linear(color.rgb);
    }
#endif
