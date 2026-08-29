import aperture;
import object_shader;
import settings;

struct FOut {
    float4 color;
}

struct VOut {
    float2 uv : TEXCOORD;
    float3 pos;
    float4 color : COLOR;
}

struct Solid : Shader<VOut, FOut> {
    static void emitVertex(Vertex v, out VOut data, out float4 pos) {
        pos = v.pos(); // player space
        data = VOut ( v.uv(), pos.xyz, v.color() ); 
    }

    static FOut shadeSurface(PixelData pixel_data, VOut vo) {
        var color = vo.color;

        if (let tex = pixel_data.albedo()) {
            color *= tex.sampleTexture(vo.uv);
        }

        ap.discardCutout(color);

        return FOut(color);
    }
}