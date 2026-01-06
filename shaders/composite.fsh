#version 330 compatibility

// FIX: Bug with lighting. Compare with tutorial image.

uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Lightmap.
uniform sampler2D colortex2; // Encoded normals.

uniform vec3 shadowLightPosition; // Sun/moon position.
uniform mat4 gbufferModelViewInverse; // To convert from view to world/player space..

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Tell Iris to up the precision of colortex0 so it can store colors properly in the linear color space. If not for this, we would lose some colors since the buffer is meant to store gamma corrected colors. Of course, increasing the precision increases the mem footprint of the buffer, hence increasing the VRAM usage.
// Further, note that this is a multi-line comment so Iris reads it. If it were a single line `//` comment, the below would not work.
/*
const int colortex0format = RGB16;
*/

const vec3 blocklight_color = vec3(1.0, 0.5, 0.08);
const vec3 skylight_color = vec3(0.05, 0.15, 0.3);
const vec3 sunlight_color = vec3(1.0);
const vec3 ambient_color = vec3(0.1);

void main() {
    // Get information from gbuffers.
    vec2 light_map = texture(colortex1, texcoord).xy;
    vec3 encoded_normal = texture(colortex2, texcoord).xyz;
    vec3 normal = normalize(encoded_normal * 2.0 - 1.0); // Undo encoding from before writing to normal buffer -- convert from [0, 1.0] to [-1.0, 1.0].

    // Sun/moon light source.
    // vec3 light_vector = normalize(shadowLightPosition);
    // vec3 light_vector_in_world_space = mat3(gbufferModelViewInverse) * light_vector;
    // float normal_aligned_with_light_vector = dot(light_vector_in_world_space, normal);
    vec3 lightVector = normalize(shadowLightPosition);
vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

    vec3 blocklight = light_map.r * blocklight_color; // x is blocklight
    vec3 skylight = light_map.g * skylight_color; // y is skylight
    // vec3 sunlight = clamp(normal_aligned_with_light_vector, 0.0, 1.0) * light_map.g * sunlight_color; // Multiply by the skylight from the light map since if an object is hidden from the sky, the object is also hidden from the sun.
    vec3 sunlight = sunlight_color * clamp(dot(worldLightVector, normal), 0.0, 1.0) * light_map.g;
    // vec3 sunlight = sunlight_color;
    vec3 ambient = ambient_color;

    // Assign color ("to main screen gbuffer").
    color = texture(colortex0, texcoord);
    // Do sky pixel check.
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }
    color.rgb *= blocklight + skylight + sunlight + ambient;
    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
