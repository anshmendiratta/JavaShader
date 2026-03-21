#if !defined INCLUDE_IN_VARIABLES
    #define INCLUDE_IN_VARIABLES

    in vec2 mc_midTexCoord;

    // `c` prefix for "custom." not to be confused with the in/out versions of these vars

    // #ifdef STAGE_VERTEX
        //     vec2 _half_size = abs(uv - mc_midTexCoord);
        //     out c_texture_bottom_left = mc_midTexCoord - half_size;
        //     out c_single_tex_size = half_size * 2.0 ;
    // #elif STAGE_FRAGMENT
        //     in vec2 c_texture_bottom_left;
        //     in vec2 c_single_tex_size;
    // #endif
#endif
