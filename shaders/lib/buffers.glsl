/*
const int colortex0Format = RGBA16F; // linear color space and hdr color buffer
const int colortex1Format = RGBA32UI; // packed material/fragment data
const int colortex4Format = R32F; // ssao
const int colortex6Format = RGBA32F; // bloom blur
const int colortex31Format = R8; // mask for hand

colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0); // for sky
colortex31ClearColor = 0; // screen mask for hand
*/

#define BUFFER_COLOR colortex0
#define BUFFER_BITPACKED_DATA colortex1
#define BUFFER_SSAO colortex4
#define BUFFER_BLOOM colortex6
#define BUFFER_HAND_MASK colortex31
