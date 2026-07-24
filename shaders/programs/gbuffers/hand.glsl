#ifdef STAGE_VERTEX
    in vec2 mc_Entity;

    flat out uint block_id;
    out vec2 uv;
    out vec2 lightmap_uv;
    out vec3 frag_normal_view;
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lightmap_uv = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        lightmap_uv = lightmap_uv / (30.0 / 32.0) - (1.0 / 32.0); // Conversion from[0.033 , 0.97 ] to[0.0 , 1.0 ] .
        glcolor = gl_Color;

        block_id = uint(mc_Entity.x);
        frag_normal_view = normalize(gl_NormalMatrix * gl_Normal);
    }
#endif

#ifdef STAGE_FRAGMENT
    flat in uint block_id;
    in vec2 uv;
    in vec2 lightmap_uv;
    in vec3 frag_normal_view;
    in vec4 glcolor;

    /* RENDERTARGETS: 0,1,31 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uvec4 bitpacked_data;
    layout(location = 2) out uint frag_is_hand;

    #include "/include/uniforms.glsl"

    #include "/include/utility/bits.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        if (color.a < alphaTestRef) discard;

        vec3 frag_normal_world = mat3(gbufferModelViewInverse) * frag_normal_view;
        vec2 frag_normal_octahedral_encoded = vector_encode_octahedral(frag_normal_world) * 0.5 + 0.5; // in [0, 1]^2

        bitpacked_data.r = packUnorm4x8(vec4(frag_normal_octahedral_encoded, vec2(
                        1., // depth
                        1. // AO
                    )));
        bitpacked_data.g = packUnorm4x8(vec4(
                    0., // perceptual smoothness
                    0., // reflectance
                    0., // porosity/sss
                    0. // emissiveness
                ));
        bitpacked_data.b = packUnorm2x16(lightmap_uv);
        bitpacked_data.a = block_id;

        frag_is_hand = 1; // buffer clear is 0 so value is 1 only for hand fragments
    }
#endif
