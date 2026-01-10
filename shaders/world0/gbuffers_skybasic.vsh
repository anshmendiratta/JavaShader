#version 330 compatibility

// Reflection.
uniform int renderStage;

out vec4 glcolor;

void main() {
    if (renderStage == MC_RENDER_STAGE_STARS) {
        return;
    }

    gl_Position = ftransform();
    glcolor = gl_Color;
}
