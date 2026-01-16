// From https://wWw.shadertoy.com/view/MdXyzX.

#define DRAG_MULT 0.38 // Changes how much waves pull on the water.
#define WATER_DEPTH 1.0 // How deep is the water.
#define CAMERA_HEIGHT 1.5 // How high the camera should be.
#define ITERATIONS_RAYMARCH 12 // Waves iterations of raymarching.
#define ITERATIONS_NORMAL 36 // Waves iterations when calculating normals.

#define NormalizedMouse (iMouse.xy / iResolution.xy) // Normalize mouse coords.

// Calculates wave value and its derivative.
// For the wave direction, position in space, wave frequency and time.
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters.
float get_waves(vec2 position, int iterations) {
    float wave_phase_shift = length(position) * 0.1; // This is to avoid every octave having exactly the same phase everywhere.
    float iter = 0.0; // This will help generating well distributed wave directions.
    float frequency = 1.0; // Frequency of the wave, this will change every iteration.
    float time_multiplier = 2.0; // Time multiplier for the wave, this will change every iteration.
    float weight = 1.0; // Weight in final sum for the wave, this will change every iteration.
    float sum_of_values = 0.0; // Will store final sum of values.
    float sum_of_weights = 0.0; // Will store final sum of weights.

    for (int i = 0; i < iterations; i++) {
        // Generate some wave direction that looks kind of random.
        vec2 p = vec2(sin(iter), cos(iter));

        // Calculate wave data.
        vec2 res = wavedx(position, p, frequency, frameTimeCounter * time_multiplier + wave_phase_shift);

        // Shift position around according to wave drag and derivative of the wave.
        position += p * res.y * weight * DRAG_MULT;

        // Add the results to sums.
        sum_of_values += res.x * weight;
        sum_of_weights += weight;

        // Modify next octave ;.
        weight = mix(weight, 0.0, 0.2);
        frequency *= 1.18;
        time_multiplier *= 1.07;

        // Add some kind of random value to make next wave look random too.
        iter += 1232.399963;
    }

    // Calculate and return.
    return sum_of_values / sum_of_weights;
}

// Take two vectors mostly along `pos`'s tangent plane and cross them.
vec3 get_water_wave_normal(vec2 pos, float epsilon, float depth) {
    vec2 ex = vec2(epsilon, 0);
    float height = get_waves(pos.xy, ITERATIONS_NORMAL) * depth;
    vec3 a = vec3(pos.x, height, pos.y);

    return normalize(
        cross(
            a - vec3(pos.x - epsilon, get_waves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y),
            a - vec3(pos.x, get_waves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + epsilon)
        )
    );
}
