package pipeline;

import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;

public class Bloom {
    public static void setup(PipelineConfig pc) {
        int lod = 2;
        pc.stage(ProgramStage.POST_RENDER).compute("bloom/downsample" + lod, "program/downsample.slang", null);
    }
}
