#if !defined INCLUDE_VOGEL_DISK_BLUR
    #define INCLUDE_VOGEL_DISK_BLUR

    #include "/include/utility/dither.glsl

    // vogel disk blur mostly taken from https://www.shadertoy.com/view/XtXXDN.
    #define GOLDEN_ANGLE 2.39996322972865332 // Radians.

    vec4 sample_colortex(sampler2D tex, vec2 uv, vec2 offset) {
        return texture(tex, uv + offset / textureSize(tex, 0));
    }

    vec2 compute_vogel_disk_sample_uv(float idx, int sample_count) {
        float dither = compute_dither(gl_FragCoord.xy);
        float radius = sqrt((idx + 0.5) / sample_count);
        float theta = idx * GOLDEN_ANGLE * dither;

        return radius * vec2(cos(theta), sin(theta));
    }

#endif
