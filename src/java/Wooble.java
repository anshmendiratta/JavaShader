import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

import pipeline.Bloom;
import pipeline.Shadow;

public abstract class Wooble implements ShaderPack {
    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {
        Shadow.setup(pipeline);
        // Bloom.setup(pipeline);
    }

    @Override
    public void configureRenderer(RendererConfig renderer) {
        renderer.setShadowCascades(4);
        renderer.setAmbientOcclusionLevel(0);
        renderer.setShadowDistance(128);
        renderer.setShadowDistance(2048);
        renderer.setSunPathRotation(-30);
    }

    @Override
    public void onNewFrame(FrameState frameState) {

    }

    @Override
    public int setBlockId(IBlockState block) {
        return 0;
    }
}
