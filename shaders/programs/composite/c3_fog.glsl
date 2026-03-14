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

    #include "/include/shadows/distort.glsl"
    #include "/include/utility/random.glsl"

    void main() {
        color = texture(colortex0, uv);

        // Do sky pixel check.
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0) {
            return;
        }

        vec3 fragment_ndc_space_position = vec3(uv.xy, depth) * 2.0 - 1.0;
        vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);

        // Fog.
        float object_distance_as_render_distance_proportion = length(fragment_view_space_position) / far;
        float fog_factor = exp(-FOG_DENSITY * (1 - object_distance_as_render_distance_proportion));

        color.rgb = mix(color.rgb, skyColor, clamp(fog_factor, 0.0, 1.0));
    }
#endif
