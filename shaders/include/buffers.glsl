/*
const int colortex0Format = RGBA16F; // linear color space and hdr color buffer
const int colortex2Format = RGB16F; // rsm
const int colortex3Format = RGB16F; // vert normals
const int colortex4Format = R32F; // ssao
const int colortex30Format = RGB16F; // bloom blur

const int shadowcolor1Format = RGBA16;

const int colortex1Format = RGBA32UI; // packed material/fragment data

const int colortex31Format = R32UI; // mask for hand

colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0); // for sky
colortex2ClearColor = vec3(0.0, 0.0, 0.0); // stores gi from rsm
colortex31ClearColor = 0; // screen mask for hand
*/

#define BUFFER_RSM colortex2
#define BUFFER_VERT_NORMAL colortex3
#define BUFFER_SSAO colortex4
#define BUFFER_BLOOM colortex30

#define BUFFER_DATA colortex1

#define BUFFER_HAND colortex31
