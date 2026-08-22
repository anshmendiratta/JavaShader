struct Interface {
    vec2 uv;
};

#ifdef STAGE_VERTEX
    out Interface v;

    #include "/include/post/taa.glsl"
    #include "/include/post/accumulation.glsl"

    void main() {
        gl_Position = ftransform();

        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/buffers.glsl"

    #include "/include/post/taa.glsl"
    #include "/include/post/accumulation.glsl"

    #include "/include/color/conversions.glsl"

    in Interface v;

    /* RENDERTARGETS: 0,20,22 */

    layout(location = 0) out vec4 color;
    layout(location = 1) out vec4 color_history;
    layout(location = 2) out float depth_history;

    void main() {
        vec2 uv = v.uv - dot(
                    vec2(dFdx(v.uv).x, dFdy(v.uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);
        vec3 reproj_uv = reproject_uv(uv, false);

        vec3 frag_pos_screen = vec3(uv, texture(depthtex0, uv).x);

        vec4 previous_frame = texture(BUFFER_TAA, reproj_uv.xy);
        vec4 current_frame = texture(colortex0, uv);

        float depth = texture(depthtex0, uv).x;
        float taa_blend = 0.875 * depth;

        color_clamp(colortex0, uv, current_frame.rgb, previous_frame.rgb);
        depth_reject(frag_pos_screen, reproj_uv, taa_blend);
        reduce_movement_blend(taa_blend);

        color = mix(current_frame, previous_frame, taa_blend);
        color_history = color;
        depth_history = texture(depthtex0, uv).x;
    }
#endif
