struct Interface {
    vec2 uv;
    vec4 glcolor;
    vec3 normal_world;
};

#ifdef STAGE_VERTEX
    out Interface v;

    #include "/include/ids.glsl"
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/utility/noise.glsl"
    #include "/include/utility/space_conversions.glsl"

    layout(r32ui) uniform uimage3D voxel_map;

    void main() {
        gl_Position = ftransform();

        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        v.glcolor = gl_Color;
        v.normal_world = mat3(shadowModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

        vec3 vert_pos_shadow_view = (gl_ModelViewMatrix * gl_Vertex).xyz;
        vec3 vert_pos_feet = shadow_view_to_feet(vert_pos_shadow_view);

        // --------------------
        //     Voxelization
        // --------------------

        vec3 pos_block_relative = vert_pos_feet + at_midBlock.xyz / 64. + fract(cameraPosition); // NOTE: understand what this does.
        ivec3 voxel_pos = ivec3(pos_block_relative + VOXEL_RADIUS);

        if (mod(gl_VertexID, 4) == 0 && clamp(voxel_pos, 0, VOXEL_AREA) == voxel_pos) {
            vec3 albedo = texture(gtexture, v.uv).rgb;
            uint voxel_data = packUnorm4x8(vec4(albedo, at_midBlock.w));

            imageAtomicMax(voxel_map, voxel_pos, voxel_data);
        }

        // ------------
        //    Waving
        // ------------

        #if WAVING_FOLIAGE == 1
            vec3 vert_world_pos = feet_to_world(vert_pos_feet);
            vec3 vert_offset_world = vec3(0.);

            vec2 noise_sample_uv = vec2(frameTimeCounter * FOLIAGE_WAVE_SPEED);
            if (mc_Entity.x == ID_ROOTED_FOLIAGE) {
                if (v.uv.y < mc_midTexCoord.y) {
                    vert_offset_world = 5.0 * FOLIAGE_WAVE_AMPLITUDE * vec3(sample_desmos_noise(noise_sample_uv + vert_world_pos.xy / 3.0), 0.0, sample_desmos_noise(noise_sample_uv + vert_world_pos.zx / 3.0));
                }
            } else if (mc_Entity.x == ID_FREE_FOLIAGE) {
                vert_offset_world = FOLIAGE_WAVE_AMPLITUDE * vec3(sample_desmos_noise(noise_sample_uv + vert_world_pos.xy), sample_desmos_noise(noise_sample_uv + vert_world_pos.yz), sample_desmos_noise(noise_sample_uv + vert_world_pos.zx));
            }

            vec3 vert_offset_shadow_view = mat3(shadowModelView) * vert_offset_world;
            vert_offset_shadow_view += vert_offset_shadow_view;
            gl_Position = shadowProjection * vec4(vert_pos_shadow_view, 1.);
        #endif

        distort_shadow_clip_position(gl_Position.xyz);
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/shadows/distort.glsl"
    #include "/include/utility/space_conversions.glsl"

    in Interface v;

    // rendertargets are shadowcolorN
    // shadowcolor1: (normal.xyz, blocker_dist).

    /* RENDERTARGETS: 0,1 */

    layout(location = 0) out vec4 color0;
    layout(location = 1) out vec4 encoded_data;

    void main() {
        color0 = texture(gtexture, v.uv) * v.glcolor;
        if (color0.a < 0.1) {
            discard;
        }

        encoded_data.xyz = v.normal_world * 0.5 + 0.5; // rsm
        encoded_data.w = 0.; // previously pcss
    }
#endif
