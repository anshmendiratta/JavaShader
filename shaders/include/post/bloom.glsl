#if !defined INCLUDE_BLOOM
    #define INCLUDE_BLOOM

    #include "/include/uniforms.glsl"
    #include "/include/settings.glsl"

    // #include "/include/utility/dither.glsl"

    // -------------
    //     Bloom
    // -------------
    // NOTE: we add one pixel padding between the tiles so the edges between mipmaps do not overlap

    vec3 bloom_downsample(in sampler2D bloom_texture, in vec2 uv);
    vec3 bloom_upsample(in sampler2D bloom_texture, in vec2 uv);

    struct BloomTile {
        vec2 origin;
        float scale;
        uint _mip;
    };

    float _x_pad = 1. / float(viewWidth);

    BloomTile _bt1 = BloomTile(vec2(0.), 0.5, 1);
    BloomTile _bt2 = BloomTile(_bt1.origin + vec2(0.5 + _x_pad, 0.), 0.25, 2);
    BloomTile _bt3 = BloomTile(_bt2.origin + vec2(0.25 + _x_pad, 0.), 0.125, 3);
    BloomTile _bt4 = BloomTile(_bt3.origin + vec2(0.125 + _x_pad, 0.), 0.0625, 4);
    BloomTile _bt5 = BloomTile(_bt4.origin + vec2(0.0625 + _x_pad, 0.), 0.03125, 5);

    BloomTile[5] bloom_tiles = BloomTile[5](_bt1, _bt2, _bt3, _bt4, _bt5);

    vec3 bloom_downsample(in sampler2D bloom_texture, in vec2 uv) {
        float x = 1. / float(viewWidth);
        float y = 1. / float(viewHeight);

        vec3 a = texture(bloom_texture, vec2(uv.x - 2. * x, uv.y + 2. * y)).rgb;
        vec3 b = texture(bloom_texture, vec2(uv.x, uv.y + 2. * y)).rgb;
        vec3 c = texture(bloom_texture, vec2(uv.x + 2. * x, uv.y + 2. * y)).rgb;

        vec3 d = texture(bloom_texture, vec2(uv.x - 2. * x, uv.y)).rgb;
        vec3 e = texture(bloom_texture, vec2(uv.x, uv.y)).rgb;
        vec3 f = texture(bloom_texture, vec2(uv.x + 2. * x, uv.y)).rgb;

        vec3 g = texture(bloom_texture, vec2(uv.x - 2. * x, uv.y - 2. * y)).rgb;
        vec3 h = texture(bloom_texture, vec2(uv.x, uv.y - 2. * y)).rgb;
        vec3 i = texture(bloom_texture, vec2(uv.x + 2. * x, uv.y - 2. * y)).rgb;

        vec3 j = texture(bloom_texture, vec2(uv.x - x, uv.y + y)).rgb;
        vec3 k = texture(bloom_texture, vec2(uv.x + x, uv.y + y)).rgb;
        vec3 l = texture(bloom_texture, vec2(uv.x - x, uv.y - y)).rgb;
        vec3 m = texture(bloom_texture, vec2(uv.x + x, uv.y - y)).rgb;

        vec3 downsample = e * 0.125;
        downsample += (a + c + g + i) * 0.03125;
        downsample += (b + d + f + h) * 0.0625;
        downsample += (j + k + l + m) * 0.125;

        return downsample;
    }

    vec3 bloom_upsample(in sampler2D bloom_texture, in vec2 uv) {
        float x = BLOOM_RADIUS / float(viewWidth);
        float y = BLOOM_RADIUS / float(viewHeight);

        vec3 a = texture(bloom_texture, vec2(uv.x - x, uv.y + y)).rgb;
        vec3 b = texture(bloom_texture, vec2(uv.x, uv.y + y)).rgb;
        vec3 c = texture(bloom_texture, vec2(uv.x + x, uv.y + y)).rgb;

        vec3 d = texture(bloom_texture, vec2(uv.x - x, uv.y)).rgb;
        vec3 e = texture(bloom_texture, vec2(uv.x, uv.y)).rgb;
        vec3 f = texture(bloom_texture, vec2(uv.x + x, uv.y)).rgb;

        vec3 g = texture(bloom_texture, vec2(uv.x - x, uv.y - y)).rgb;
        vec3 h = texture(bloom_texture, vec2(uv.x, uv.y - y)).rgb;
        vec3 i = texture(bloom_texture, vec2(uv.x + x, uv.y - y)).rgb;

        vec3 upsample = e * 4.;
        upsample += (b + d + f + h) * 2.;
        upsample += (a + c + g + i);
        upsample *= 1. / 16.;

        return upsample;
    }

    // line two basically taken from shrimple: https://github.com/Null-MC/Shrimple/blob/f4fcab627cc62bd2e66813c58cd657bb4ecbb84f/shaders/include/effects/bloom.glsl#L132
    // void dither_bloom(inout vec3 color) {
    //     float dither = compute_dither(gl_FragCoord.xy);
    //     color += (dither - 0.25) / 32.0e3;
    // }

    // ------------------
    //     UV mapping
    // ------------------

    vec2 map_uv_to_tile(in vec2 uv, uint mip) {
        if (mip == 0) return uv;

        BloomTile bt = bloom_tiles[mip - 1];
        return uv * bt.scale + bt.origin;
    }

    // vec2 map_tile_to_uv(in vec2 tile_uv, uint mip) {
    //     BloomTile bt = bloom_tiles[mip - 1];
    //     return (tile_uv - bt.origin) / bt.scale;
    // }
#endif
