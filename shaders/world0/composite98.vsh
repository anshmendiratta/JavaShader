#version 430 compatibility

// ----------
// Smart denoiser. Source in .fsh
// ----------

out vec2 atlas_uv;

void main() {
    gl_Position = ftransform();
    atlas_uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}