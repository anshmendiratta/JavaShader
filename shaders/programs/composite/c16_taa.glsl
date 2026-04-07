#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0,7 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out vec4 history;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/post/taa.glsl"

    void main() {
        // Sample current frame color (output from bloom application)
        vec4 current_color = texture(colortex0, uv);

        // Apply TAA using previous frame stored in colortex7 as history
        vec3 taa_color = apply_taa_simple(
                uv,
                current_color.rgb,
                colortex7, // history buffer
                depthtex0 // depth texture
            );

        // Output TAA result to main buffer
        // color = current_color;
        color = vec4(taa_color, 1.0);

        // Store this frame as history for next frame
        history = vec4(taa_color, 1.0);
    }
#endif
