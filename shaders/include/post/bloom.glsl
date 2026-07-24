#if !defined INCLUDE_BLOOM
    #define INCLUDE_BLOOM

    #include "/include/uniforms.glsl"
    #include "/include/settings.glsl"

    #include "/include/color/conversions.glsl"

    // -------------
    //     Bloom
    // -------------
    // NOTE: we add one pixel padding between the tiles so the edges between mipmaps do not overlap

    vec3 bloom_downsample(in sampler2D bloom_texture, in vec2 uv);
    vec3 bloom_upsample(in sampler2D bloom_texture, in vec2 uv);
    float _karis_average(vec3 color);

    vec2 map_uv_to_tile(in vec2 uv, uint mip);
    vec2 clamp_sample_uv_to_tile(in vec2 tile_uv, in uint mip);

    struct BloomTile {
        vec2 origin;
        float scale;
    };

    float _x_pad = 1. / float(viewWidth);

    BloomTile _bt1 = BloomTile(vec2(0.), 0.5);
    BloomTile _bt2 = BloomTile(_bt1.origin + vec2(0.5 + _x_pad, 0.), 0.25);
    BloomTile _bt3 = BloomTile(_bt2.origin + vec2(0.25 + _x_pad, 0.), 0.125);
    BloomTile _bt4 = BloomTile(_bt3.origin + vec2(0.125 + _x_pad, 0.), 0.0625);
    BloomTile _bt5 = BloomTile(_bt4.origin + vec2(0.0625 + _x_pad, 0.), 0.03125);

    BloomTile[5] bloom_tiles = BloomTile[5](_bt1, _bt2, _bt3, _bt4, _bt5);

    vec3 bloom_downsample(in sampler2D bloom_texture, in vec2 uv, in uint mip) {
        float x = 1. / float(viewWidth);
        float y = 1. / float(viewHeight);

        vec3 a = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - 2. * x, uv.y + 2. * y), mip)).rgb;
        vec3 b = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y + 2. * y), mip)).rgb;
        vec3 c = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + 2. * x, uv.y + 2. * y), mip)).rgb;

        vec3 d = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - 2. * x, uv.y), mip)).rgb;
        vec3 e = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y), mip)).rgb;
        vec3 f = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + 2. * x, uv.y), mip)).rgb;

        vec3 g = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - 2. * x, uv.y - 2. * y), mip)).rgb;
        vec3 h = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y - 2. * y), mip)).rgb;
        vec3 i = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + 2. * x, uv.y - 2. * y), mip)).rgb;

        vec3 j = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - x, uv.y + y), mip)).rgb;
        vec3 k = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + x, uv.y + y), mip)).rgb;
        vec3 l = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - x, uv.y - y), mip)).rgb;
        vec3 m = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + x, uv.y - y), mip)).rgb;

        vec3 downsample = vec3(0.);
        vec3 groups[5];

        if (mip == 1) {
            groups[0] = (a + b + d + e) * (0.125f / 4.0f);
            groups[1] = (b + c + e + f) * (0.125f / 4.0f);
            groups[2] = (d + e + g + h) * (0.125f / 4.0f);
            groups[3] = (e + f + h + i) * (0.125f / 4.0f);
            groups[4] = (j + k + l + m) * (0.5f / 4.0f);
            groups[0] *= _karis_average(groups[0]);
            groups[1] *= _karis_average(groups[1]);
            groups[2] *= _karis_average(groups[2]);
            groups[3] *= _karis_average(groups[3]);
            groups[4] *= _karis_average(groups[4]);
            downsample = groups[0] + groups[1] + groups[2] + groups[3] + groups[4];
        } else {
            downsample = e * 0.125;
            downsample += (a + c + g + i) * 0.03125;
            downsample += (b + d + f + h) * 0.0625;
            downsample += (j + k + l + m) * 0.125;
        }

        return downsample;
    }

    vec3 bloom_upsample(in sampler2D bloom_texture, in vec2 uv, in uint mip) {
        float x = BLOOM_RADIUS / float(viewWidth);
        float y = BLOOM_RADIUS / float(viewHeight);

        vec3 a = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - x, uv.y + y), mip)).rgb;
        vec3 b = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y + y), mip)).rgb;
        vec3 c = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + x, uv.y + y), mip)).rgb;

        vec3 d = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - x, uv.y), mip)).rgb;
        vec3 e = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y), mip)).rgb;
        vec3 f = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + x, uv.y), mip)).rgb;

        vec3 g = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x - x, uv.y - y), mip)).rgb;
        vec3 h = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x, uv.y - y), mip)).rgb;
        vec3 i = texture(bloom_texture, clamp_sample_uv_to_tile(vec2(uv.x + x, uv.y - y), mip)).rgb;

        vec3 upsample = e * 4.;
        upsample += (b + d + f + h) * 2.;
        upsample += (a + c + g + i);
        upsample *= 1. / 16.;

        return upsample;
    }

    float _karis_average(vec3 color) {
        float luma = rgb_to_luminance(linear_to_rgb(color)) * 0.25;
        return 1. / (1. + luma);
    }

    // ------------------
    //     UV mapping
    // ------------------

    vec2 map_uv_to_tile(in vec2 uv, uint mip) {
        if (mip == 0) return uv;

        BloomTile bt = bloom_tiles[mip - 1];
        return uv * bt.scale + bt.origin;
    }

    vec2 clamp_sample_uv_to_tile(in vec2 tile_uv, in uint mip) {
        BloomTile bt = mip == 0 ? BloomTile(vec2(0.), 1.) : bloom_tiles[mip - 1];
        vec2 tile_min = bt.origin;
        vec2 tile_max = bt.origin + bt.scale;
        return clamp(tile_uv, tile_min, tile_max);
    }
#endif
