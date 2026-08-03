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

    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/atmosphere.glsl"

    #include "/include/color/conversions.glsl"

    void main() {
        color = texture(colortex0, uv);
        // ignore sky / dh
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0) {
            // FIX: clouds are still being ignored. try using cloudDistance for clouds specifically instead of the far plane
            return;
        }

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 fragment_view_space_position = ndc_to_view(vec3(uv, depth) * 2.0 - 1.0);
        vec3 fragment_world_space_position = view_to_world(fragment_view_space_position);

        // Fog.
        float object_distance_as_render_distance_proportion = length(fragment_view_space_position) / far;
        float fog_factor = exp(-FOG_DENSITY * (1. - object_distance_as_render_distance_proportion));

        fragment_world_space_position.y *= -1;
        fragment_view_space_position = world_to_view(fragment_world_space_position);
        vec3 sky_color_at_horizon = get_pbr_sky_color(fragment_view_space_position);

        color.rgb = oklab_mix(color.rgb, rgb_to_linear(fogColor), clamp01(fog_factor));
        // color . rgb = sky_color_at_horizon;
        // color . rgb = vec3(1., 0., 0.);
    }
#endif