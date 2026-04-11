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

    #include "/include/uniforms.glsl"

    #include "/include/lighting/ssr.glsl"

    #include "/include/pbr/material.glsl"

    #include "/include/utility/space_conversions.glsl"

    void main() {
        vec4 original_color = texture(colortex0, uv);
        color = original_color;

        if (fragment_is_hand(uv)) return; // don't reflect hand

        Material material;
        init_material_unpacked_colortex_read(material);

        vec3 frag_position_screen = vec3(uv, texture(depthtex0, uv).r);
        vec3 frag_position_view = normalize(screen_to_view(frag_position_screen));

        vec3 frag_normal_view = normalize(mat3(gbufferModelView) * material.normal);
        vec3 frag_reflected_ray_view = reflect(frag_position_view, frag_normal_view);

        vec2 reflected_uv = raymarch_ssr(material, uv, frag_position_view, frag_reflected_ray_view);
        vec3 reflected_color = texture(colortex0, reflected_uv).rgb;

        color.rgb = mix(original_color.rgb, reflected_color, SSR_VISIBILITY);
    }
#endif
