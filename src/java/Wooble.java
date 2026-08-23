import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

import pipeline.Bloom;
import pipeline.Shadow;
<<<<<<< HEAD
import util.Textures;

public abstract class Wooble implements ShaderPack {
    @Override
    public void configurePipeline(Screen screen, PipelineConfig pc) {
        pc.combinationPass("post/combination");

        // final var texture = new Textures(pc, screen);
        var scene_tex = pc.texture2D("scene_tex", TextureFormat.RGBA8_UNORM).renderSize().create();

        pc.object(ProgramUsage.BASIC, "object/solid", "Solid").writes("color", scene_tex);
        pc.object(ProgramUsage.TRANSLUCENT, "object/solid", "Solid").writes("color", scene_tex);
        pc.object(ProgramUsage.SHADOW, "object/solid", "Solid").writes("color", scene_tex);

        pc.stage(ProgramStage.PRE_RENDER).clearToFogColor(scene_tex);
    }

    @Override
    public void configureRenderer(RendererConfig renderer) {
        // renderer.setShadowCascades(4);
        renderer.setAmbientOcclusionLevel(0);
        renderer.setShadowDistance(128);
        renderer.setShadowResolution(2048);
        renderer.setSunPathRotation(-30);
    }
}
