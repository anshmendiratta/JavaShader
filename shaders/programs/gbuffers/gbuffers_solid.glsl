#ifdef STAGE_VERTEX
    in vec2 mc_midTexCoord;
    in vec2 mc_Entity;
    in vec4 at_tangent;

    out vec2 uv;
    out vec2 lightmap_uv;
    out vec2 texture_bottom_left; // vec2(x_min, y_min).
    out vec2 single_tex_size; // vec2(x_range, y_range).
    out vec3 normal_view_space;
    out vec3 tangent_view_space;
    out vec4 glcolor;

    #include "/lib/settings.glsl"

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

        normal_view_space = mc_Entity.x == 10000.0 ? gl_NormalMatrix * vec3(0.0, 1.0, 0.0) : normalize(gl_NormalMatrix * gl_Normal); // View space.
        #if NORMAL_MAPPING == 1
            normal_view_space = normalize(gl_NormalMatrix * gl_Normal); // View space.
            tangent_view_space = normalize(at_tangent.w * (gl_NormalMatrix * at_tangent.xyz)); // View space.
        #endif

        #if WAVING_FOLIAGE == 1
            // Waving foliage.
            // TODO: foliage "jitters" when the camera does.
            vec3 vertex_view_space_position = (gbufferProjectionInverse * gl_Position).xyz;
            vec3 vertex_player_space_position = (gbufferModelViewInverse * vec4(vertex_view_space_position, 1.0)).xyz;
            vec3 vertex_world_space_position = vertex_player_space_position + cameraPosition;
            vec3 vertex_offset_world_space = vec3(0.0, 0.0, 0.0);

            // TODO: Make look nicer.
            if (mc_Entity.x == ID_ROOTED_FOLIAGE) { // Rooted foliage.
                // TOOD: Figure out why this check doesn't just move one half of the block.
                if (uv.y < mc_midTexCoord.y) {
                    vertex_offset_world_space = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.xy / 3.0),
                                0.0,
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.zx / 3.0)
                            );
                }
            } else if (mc_Entity.x == ID_FREE_FOLIAGE) { // Leaves.
                vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.xy),
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.yz),
                            sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.zx)
                        );
            }

            vec3 vertex_offset_view_space = mat3(gbufferModelView) * vertex_offset_world_space;
            vertex_view_space_position += vertex_offset_view_space;
            gl_Position = gbufferProjection * vec4(vertex_view_space_position, 1.0);
        #endif
    }
#endif

#ifdef STAGE_FRAGMENT
    uniform float alphaTestRef = 0.1;

    in vec4 glcolor;
    in vec3 tangent_view_space;
    in vec3 normal_view_space;
    in vec2 lightmap_uv;
    in vec2 uv;
    in vec2 texture_bottom_left; // vec2(x_min, y_min).
    in vec2 single_tex_size; // vec2(x_range, y_range).

    /* RENDERTARGETS: 0,1 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uvec4 bitpacked_data; // normal map (4x u8), specular map (4x u8), lightmap uv (2x half), uv (2x half)

    #include "/lib/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"

    #include "/include/pbr/textures.glsl"
    #if POM == 1
        #include "/include/pbr/parallax.glsl"
    #endif

    void main() {
        vec3 bitangent_view_space = normalize(cross(tangent_view_space, normal_view_space));
        mat3 TBN_matrix = mat3(tangent_view_space, bitangent_view_space, normal_view_space);

        #if POM == 1
            vec3 fragment_ndc_space_position = vec3(uv, texture(depthtex0, uv).r) * 2.0 - 1.0;
            vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
            vec3 view_direction_view_space = normalize(fragment_view_space_position);
            vec3 view_direction_tangent_space = transpose(TBN_matrix) * view_direction_view_space;
            vec2 local_uv = atlas_uv_to_local(uv, texture_bottom_left, single_tex_size);
            vec2 pom_local_uv = pom_uv_transform(local_uv, view_direction_tangent_space);
            vec2 pom_atlas_uv = local_uv_to_atlas(pom_local_uv, texture_bottom_left, single_tex_size);
            uv = pom_atlas_uv;
        #endif

        // packing
        #if NORMAL_MAPPING == 1
            vec4 normal_map_read = read_texture(normals, uv);
            normal_map_read.xy = normal_map_read.xy * 2.0 - 1.0;
            vec3 normal_normal_space = vec3(normal_map_read.xy, sqrt(1.0 - dot(normal_map_read.xy, normal_map_read.xy)));
            vec3 normal_view_space = TBN_matrix * normal_normal_space;
            vec3 normal_world_space = normalize(mat3(gbufferModelViewInverse) * normal_view_space);
            vec2 normal_octahedral_encoded = vector_encode_octahedral(normal_world_space); // in the range [0, 1]^2
            bitpacked_data.r = packUnorm4x8(vec4(normal_octahedral_encoded, normal_map_read.zw));
        #else
            // same deal as normal mapping but use all bits for octahedral encoded normal.xy
            vec3 normal_world_space = normalize(mat3(gbufferModelViewInverse) * normal_view_space);
            vec2 normal_octahedral_encoded = vector_encode_octahedral(normal_world_space);
            bitpacked_data.r = packUnorm2x16(normal_octahedral_encoded);
        #endif
        #if SPECULAR_MAPPING == 1
            vec4 specular_map_read = read_texture(normals, uv);
            bitpacked_data.g = packUnorm4x8(specular_map_read);
        #endif
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        bitpacked_data.a = packUnorm2x16(uv);

        #if SPECULAR_MAPPING == 1
            float emissive_strength = normal_map_read.a;
            color = emissive_strength * read_texture(gtexture, uv) * glcolor; // Block texture with biome color.
        #else
            color = read_texture(gtexture, uv) * glcolor; // Block texture with biome color.
        #endif

        // manual alpha testing
        if (color.a < alphaTestRef) {
            discard;
        }
    }
#endif
