// --- Shadows ---
#define SHADOW_MAP_RESOLUTION 1024 // Shadow map resolution in pixels. [512 1024 2048 4096]
#define NOISE_TEXTURE_RESOLUTION 256 // Resolution of the noise texture used to randomize box kernel sampling of the shadow map. [256 512 1024 2048]
#define SHADOW_BIAS 1.0 // Bias used to mitigate shadow acne. [1.0 1.1 1.2 1.3 1.4 1.5]

// --- Sky ---
// Blocklight.
#define BLOCKLIGHT_COLOR_R 1.0 // Blocklight color red content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define BLOCKLIGHT_COLOR_G 1.0 // Blocklight color green content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define BLOCKLIGHT_COLOR_B 1.0 // Blocklight color blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
// Skylight.
#define SKYLIGHT_COLOR_R 0.5 // Skylight color red content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKYLIGHT_COLOR_G 0.5 // Skylight color green content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKYLIGHT_COLOR_B 0.5 // Skylight color blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_START_R 0.3 // Sky near the sun red content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_START_G 0.58 // Sky near the sun green content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_START_B 1.0 // Sky near the sun blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_END_R 0.75 // Sky opposite the sun red content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_END_G 0.84 // Sky opposite the sun green content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define SKY_COLOR_END_B 1.0 // Sky opposite the sun blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
// Intensities.
#define SUNLIGHT_COLOR_INTENSITY 0.8 // Skylight color blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define MOONLIGHT_COLOR_INTENSITY 0.1 // Skylight color blue content. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define AMBIENT_COLOR_INTENSITY 0.2 // Skylight color blue content. [0.0 0.10.2 0.3 0.4 0.5 0.6 0.7 0.8]

#define WATER_WAVE_AMPLITUDE 0.3 // How high a water wave can go. Do not interpret this value as blocks/meters. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// --- Materials ---
#define LABPBR_ENABLED

// --- Dev ---
#define DEBUG_VIEW
