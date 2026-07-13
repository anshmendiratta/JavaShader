#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 2 */

    layout(location = 0) out vec3 rsm_gi; // reflective shadow map global illumuination

    #include "/include/uniforms.glsl"

    #include "/include/pbr/textures.glsl"
    #include "/include/pbr/material.glsl"

    #include "/include/shadows/rsm.glsl"

    void main() {
        // Material material;
        // init_material_unpacked_colortex_read(material);

        vec3 frag_pos_screen = vec3(uv, texture(depthtex0, uv).r);
        vec3 frag_pos_world = view_to_world(screen_to_view(frag_pos_screen));

        vec3 frag_vert_normal = texture(colortex3, uv).xyz * 2. - 1.;

        rsm_gi = compute_rsm_gi(frag_pos_world, frag_vert_normal);
    }
#endif
