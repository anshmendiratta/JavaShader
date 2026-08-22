#ifdef STAGE_VERTEX
    out vec2 uv;
    out vec4 star_data; // rgb = star color, a = flag for weather or not this pixel is a star .
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        star_data = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
        glcolor = gl_Color;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec4 star_data; // rgb = star color, a = flag for whether or not this pixel is a star.
    in vec2 uv;
    in vec4 glcolor;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/atmosphere.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/utility/intersect.glsl"
    #include "/include/utility/coordinates.glsl"

    writeonly uniform image3D skycolor_map;

    void main() {
        vec3 screen_uv = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z);
        vec3 frag_pos_view = screen_to_view(screen_uv);
        vec3 frag_pos_feet = view_to_feet(frag_pos_view);

        if (star_data.a == 1.0) {
            const float SNAP_GRID_SIZE = 0.1;
            vec3 frag_snapped_pos_feet = floor(frag_pos_feet * SNAP_GRID_SIZE) / SNAP_GRID_SIZE;
            float twinkle_delay = 2. * dot(frag_snapped_pos_feet, vec3(1.));
            float twinkle_brightness = 0.3 * sin(5e-3 * frameCounter + twinkle_delay) + 0.7; // TODO: change from frameCounter to worldTime
            color = vec4(twinkle_brightness * star_data.rgb, 1.0);
            return;
        }

        #if PBR_SKY == 1.0
            vec3 dir = mat3(gbufferModelViewInverse) * normalize(frag_pos_view);
            color.rgb = getSky(dir, true);
        #else
            vec3 frag_vector_world = mat3(gbufferModelViewInverse) * normalize(frag_pos_view); // treat as vector
            float up_factor = max0(frag_vector_world.y); // frag_player dot { 0, 1, 0 }
            color.rgb = get_sky_color(SRGB_TO_ACESCG * rgb_to_linear(skyColor), SRGB_TO_ACESCG * rgb_to_linear(fogColor), up_factor);
        #endif

        vec3 frag_pos_world = feet_to_world(frag_pos_feet);

        imageStore(skycolor_map, ivec3(frag_pos_world), color);
    }
#endif
