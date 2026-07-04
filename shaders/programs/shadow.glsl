
#ifdef STAGE_VERTEX
    in vec2 mc_midTexCoord;
    in vec2 mc_Entity;

    out vec2 uv;
    out vec4 glcolor;
    out vec3 normal_world;

    #include "/include/ids.glsl"
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/utility/noise.glsl"
    #include "/include/utility/space_conversions.glsl"

    void main() {
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
        gl_Position = ftransform();
        normal_world = mat3(shadowModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

        #if WAVING_FOLIAGE == 1
            vec3 vertex_shadow_view_space_position = (gl_ModelViewMatrix * gl_Vertex).xyz;
            vec3 vertex_feet_space_position = shadow_view_to_feet(vertex_shadow_view_space_position);
            vec3 vertex_world_space_position = feet_to_world(vertex_feet_space_position);
            vec3 vertex_offset_world_space = vec3(0.);

            vec2 noise_sample_uv = vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED);
            if (mc_Entity.x == ID_ROOTED_FOLIAGE) {
                if (uv.y < mc_midTexCoord.y) {
                    vertex_offset_world_space = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(sample_desmos_noise(noise_sample_uv + vertex_world_space_position.xy / 3.0), 0.0, sample_desmos_noise(noise_sample_uv + vertex_world_space_position.zx / 3.0));
                }
            } else if (mc_Entity.x == ID_FREE_FOLIAGE) {
                vertex_offset_world_space = FOLIAGE_WAVE_AMPLITUDE * vec3(sample_desmos_noise(noise_sample_uv + vertex_world_space_position.xy), sample_desmos_noise(noise_sample_uv + vertex_world_space_position.yz), sample_desmos_noise(noise_sample_uv + vertex_world_space_position.zx));
            }

            // Apply offset(s).
            vec3 vertex_offset_shadow_view_space = mat3(shadowModelView) * vertex_offset_world_space;
            vertex_shadow_view_space_position += vertex_offset_shadow_view_space;
            gl_Position = shadowProjection * vec4(vertex_shadow_view_space_position, 1.0);
        #endif

        distort_shadow_clip_position(gl_Position.xyz);
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/utility/space_conversions.glsl"

    in vec2 uv;
    in vec3 normal_world;
    in vec4 glcolor;

    // rendertargets are shadowcolorN
    // shadowcolor1: (normal.xyz, blocker_dist).

    /* RENDERTARGETS: 0,1 */

    layout(location = 0) out vec4 color0;
    layout(location = 1) out vec4 encoded_data;

    void main()
    {
        color0 = texture(gtexture, uv);
        if (color0.a < 0.1) {
            discard;
        }

        encoded_data.xyz = normal_world * 0.5 + 0.5; // rsm
        encoded_data.w = 0.; // previously pcss
    }
#endif
