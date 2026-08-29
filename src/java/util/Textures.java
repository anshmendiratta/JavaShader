package util;


import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;

import util.Flipper;

public class Textures {
    // textures that require flipping
    public final Flipper<Texture2D> scene_tex;
    public final Flipper<Texture2D> bloom_tex;

    // effect outputs

    public Textures(PipelineConfig pc, Screen screen) {
        final float screen_height = screen.renderHeight();
        final float screen_width = screen.renderWidth();

        final Texture2D scene_tex_a = pc.texture2D("scene_tex_a", TextureFormat.RGBA16_UNORM).renderSize().create();
        final Texture2D scene_tex_b = pc.texture2D("scene_tex_b", TextureFormat.RGBA16_UNORM).renderSize().create();
        scene_tex = new Flipper<Texture2D>(scene_tex_a, scene_tex_b);

        final Texture2D bloom_tex_a = pc.texture2D("bloom_tex_a", TextureFormat.RGBA16_UNORM).size((int) (screen_width),
                (int) (screen_height / 2)).create();
        final Texture2D bloom_tex_b = pc.texture2D("bloom_tex_b", TextureFormat.RGBA16_UNORM).size((int) (screen_width),
                (int) (screen_height / 2)).create();
        bloom_tex = new Flipper<Texture2D>(bloom_tex_a, bloom_tex_b);
    }
}
