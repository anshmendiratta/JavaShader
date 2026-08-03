#version 430 compatibility

void main() {
    gl_Position = ftransform();

    atlas_uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
