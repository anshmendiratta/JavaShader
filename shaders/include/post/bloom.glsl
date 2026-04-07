#if !defined INCLUDE_BLOOM
    #define INCLUDE_BLOOM

    #include "/include/utility/dither.glsl"

    // 13-tap downsampling with Karis average (prevents firefly artifacts)
    // texel_size = 1.0 / texture_resolution
    vec3 bloom_downsample(sampler2D bloom_texture, vec2 uv, vec2 texel_size) {
        // Take 13 samples - 1 center, 4 corners (a), 4 mid-edges (b), 4 inner corners (c)
        vec3 a = texture(bloom_texture, uv + texel_size * vec2(-2.0, -2.0)).rgb;
        vec3 b = texture(bloom_texture, uv + texel_size * vec2( 0.0, -2.0)).rgb;
        vec3 c = texture(bloom_texture, uv + texel_size * vec2( 2.0, -2.0)).rgb;
        vec3 d = texture(bloom_texture, uv + texel_size * vec2(-2.0,  0.0)).rgb;
        vec3 e = texture(bloom_texture, uv + texel_size * vec2( 0.0,  0.0)).rgb;
        vec3 f = texture(bloom_texture, uv + texel_size * vec2( 2.0,  0.0)).rgb;
        vec3 g = texture(bloom_texture, uv + texel_size * vec2(-2.0,  2.0)).rgb;
        vec3 h = texture(bloom_texture, uv + texel_size * vec2( 0.0,  2.0)).rgb;
        vec3 i = texture(bloom_texture, uv + texel_size * vec2( 2.0,  2.0)).rgb;
        
        vec3 j = texture(bloom_texture, uv + texel_size * vec2(-1.0, -1.0)).rgb;
        vec3 k = texture(bloom_texture, uv + texel_size * vec2( 1.0, -1.0)).rgb;
        vec3 l = texture(bloom_texture, uv + texel_size * vec2(-1.0,  1.0)).rgb;
        vec3 m = texture(bloom_texture, uv + texel_size * vec2( 1.0,  1.0)).rgb;
        
        // Apply weighted distribution
        // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1.0
        vec3 result = e * 0.125;
        result += (a + c + g + i) * 0.03125;
        result += (b + d + f + h) * 0.0625;
        result += (j + k + l + m) * 0.125;
        
        return result;
    }

    // 9-tap tent filter upsampling
    // radius controls the spread of the blur
    vec3 bloom_upsample(sampler2D bloom_texture, vec2 uv, vec2 texel_size, float radius) {
        // Take 9 samples in a tent filter pattern
        vec3 a = texture(bloom_texture, uv + texel_size * vec2(-1.0, -1.0) * radius).rgb;
        vec3 b = texture(bloom_texture, uv + texel_size * vec2( 0.0, -1.0) * radius).rgb;
        vec3 c = texture(bloom_texture, uv + texel_size * vec2( 1.0, -1.0) * radius).rgb;
        
        vec3 d = texture(bloom_texture, uv + texel_size * vec2(-1.0,  0.0) * radius).rgb;
        vec3 e = texture(bloom_texture, uv + texel_size * vec2( 0.0,  0.0) * radius).rgb;
        vec3 f = texture(bloom_texture, uv + texel_size * vec2( 1.0,  0.0) * radius).rgb;
        
        vec3 g = texture(bloom_texture, uv + texel_size * vec2(-1.0,  1.0) * radius).rgb;
        vec3 h = texture(bloom_texture, uv + texel_size * vec2( 0.0,  1.0) * radius).rgb;
        vec3 i = texture(bloom_texture, uv + texel_size * vec2( 1.0,  1.0) * radius).rgb;
        
        // Apply tent filter weights (bilinear)
        vec3 result = e * 4.0;
        result += (b + d + f + h) * 2.0;
        result += (a + c + g + i);
        result *= 1.0 / 16.0;
        
        return result;
    }

    // line two basically taken from shrimple: https://github.com/Null-MC/Shrimple/blob/f4fcab627cc62bd2e66813c58cd657bb4ecbb84f/shaders/include/effects/bloom.glsl#L132
    void dither_bloom(inout vec3 color) {
        float dither = compute_dither(gl_FragCoord.xy);
        color += (dither - 0.25) / 32.0e3;
    }
#endif
