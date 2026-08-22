#ifdef STAGE_VERTEX
    out vec2 uv;
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/utility/intersect.glsl"
    #include "/include/utility/coordinates.glsl"

    in vec2 uv;
    in vec4 glcolor;

    /* RENDERTARGETS: 0,30 */

    layout(location = 0) out vec4 color;
    layout(location = 1) out uint frag_is_cloud;

    writeonly uniform image3D cloud_map;

    void main() {
        color = texture(gtexture, uv) * glcolor;

        vec3 screen_uv = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z);
        vec3 frag_pos_feet = view_to_feet(screen_to_view(screen_uv));
        vec3 frag_pos_world = feet_to_world(frag_pos_feet);

        float cosine_to_horizon = abs(frag_pos_feet.y); // dot(vec3(0., 1., 0.), frag_pos_feet)

        color.a = mix(0., color.a, pow2(clamp01(cosine_to_horizon)));
        frag_is_cloud = 1;

        imageStore(cloud_map, ivec3(frag_pos_world.xy, cloudHeight), color);
    }
#endif
