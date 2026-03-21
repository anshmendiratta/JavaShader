/*
const int colortex0Format = RGBA16F; // linear color space and hdr color buffer
const int colortex1Format = RGBA32UI; // packed material/fragment data
const int colortex4Format = R32F; // ssao
const int colortex6Format = RGBA32F; // bloom blur
*/

#define BUFFER_COLOR colortex0
#define BUFFER_BITPACKED_DATA colortex1
#define BUFFER_SSAO colortex4
#define BUFFER_BLOOM colortex6
