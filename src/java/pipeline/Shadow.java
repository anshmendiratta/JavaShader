package pipeline;

import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramUsage;

public class Shadow {
    public static void setup(PipelineConfig pc) {
        pc.object(ProgramUsage.SHADOW, "programs/object/shadow", "Shadow");
    }
}
