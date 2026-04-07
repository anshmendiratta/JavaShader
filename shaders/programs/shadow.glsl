
#ifdef STAGE_VERTEX
    in vec2 mc_midTexCoord;
    in vec2 mc_Entity;

    out vec2 uv;
    out vec4 glcolor;
    out vec3 normal_view_space;

    #include "/include/ids.glsl"
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/utility/noise.glsl"

    void main() {
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
        gl_Position = ftransform();
        normal_view_space = normalize(gl_NormalMatrix * gl_Normal);

        #if WAVING_FOLIAGE == 1
            // Waving foliage.
            // TODO: foliage "jitters" when the camera does.
            vec3 vertex_shadow_view_space_position = (gl_ModelViewMatrix * gl_Vertex).xyz;
            vec3 vertex_feet_space_position = (shadowModelViewInverse * vec4(vertex_shadow_view_space_position, 1.0)).xyz;
            vec3 vertex_world_space_position = vertex_feet_space_position + cameraPosition;
            vec3 vertex_offset_world_space = vec3(0.0, 0.0, 0.0);

            // TODO: Make look nicer.
            if (mc_Entity.x == ID_ROOTED_FOLIAGE) {
                if (uv.y < mc_midTexCoord.y) {
                    vertex_offset_world_space = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.xy / 3.0),
                                0.0,
                                sample_desmos_noise(vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED) + vertex_world_space_position.zx / 3.0)
                            );
                }
            } else if (mc_Entity.x == ID_FREE_FOLIAGE) {
                vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(
                            sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.xy),
                            sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.yz),
                            sample_desmos_noise(vec2(FOLIAGE_WAVE_SPEED * frameTimeCounter) + vertex_world_space_position.zx)
                        );
            } else if (mc_Entity.x == ID_WATER) {
                vertex_offset_world_space = WATER_WAVE_AMPLITUDE * vec3(
                            0.0,
                            compute_wave_displacement(vertex_world_space_position.xz, 3),
                            0.0
                        );
            }

            // Apply offset(s).
            vec3 vertex_offset_shadow_view_space = mat3(shadowModelView) * vertex_offset_world_space;
            vertex_shadow_view_space_position += vertex_offset_shadow_view_space;
            gl_Position = shadowProjection * vec4(vertex_shadow_view_space_position, 1.0);
        #endif

        gl_Position.xyz = distort_shadow_clip_position(gl_Position.xyz);
    }
#endif

// TODO: store sss and rsm info somewhere

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/lighting/subsurface_scattering.glsl"

    in vec2 uv;
    in vec4 glcolor;
    in vec3 normal_view_space;

    // rendertargets are shadowcolorN (N = 0, 1)
    /* RENDERTARGETS: 0,1 */
    layout(location = 0) out vec4 color0;
    layout(location = 1) out vec4 encoded_information;

    //               encoded_information
    //
    // |          R          G          B          |          A          |
    // |-------------------------------------------|---------------------|
    // |               encoded normal              |      SSS depth      |

    void main() {
        color0 = texture(gtexture, uv) * glcolor;
        if (color0.a < 0.1) {
            discard;
        }

        // for rsm
        encoded_information.rgb = normal_view_space * 0.5 + 0.5;

        // store
        // encoded_information.a =
    }
#endif
