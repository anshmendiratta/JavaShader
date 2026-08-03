/*
const int colortex0Format = RGBA16F; // linear color space and hdr color buffer
colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0); // for sky

const int colortex2Format = RGB16F; // rsm
colortex2ClearColor = vec3(0.0, 0.0, 0.0); // stores gi from rsm
const int colortex4Format = R32F; // ssao
const int colortex29Format = RGB16F; // bloom blur

const int colortex20Format = RGBA16F; // TAA
const bool colortex20Clear = false;
const int colortex21Format = RGBA16F; // ssr
const bool colortex21Clear = false;
const int colortex22Format = R16F; // previous depth
const bool colortex22Clear = false;

const int shadowcolor1Format = RGBA16;

const int colortex1Format = RGBA32UI; // packed material/fragment data
const int colortex3Format = RGB16F; // vert normals

const int colortex30Format = R32UI; // mask for clouds
const int colortex31Format = R32UI; // mask for hand
*/

// Effects.
#define BUFFER_RSM colortex2
#define BUFFER_SSAO colortex4
#define BUFFER_BLOOM colortex29

// Relegated to the trenches.
#define BUFFER_TAA colortex20
#define BUFFER_SSR_ACC colortex21
#define BUFFER_PREVIOUS_DEPTH colortex22

// Data.
#define BUFFER_DATA colortex1
#define BUFFER_VERT_NORMAL colortex3

// Masks/misc.
#define BUFFER_CLOUDS colortex30
#define BUFFER_HAND colortex31
