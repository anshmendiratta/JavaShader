import aperture;

Texture2D scene_tex;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    return scene_tex[pos];
}
