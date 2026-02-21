// Lambertian lighting model.

in vec2 uv;
in vec2 lmcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/settings.glsl"
#include "/include/uniforms.glsl"
#include "/include/utility/random.glsl"
#include "/include/utility/space_conversions.glsl"
#include "/include/utility/noise.glsl"
#include "/include/lighting/diffuse.glsl"
#include "/include/lighting/specular.glsl"
#include "/include/shadows/distort.glsl"
#include "/include/shadows/compute.glsl"

void main() {
    color = texture(colortex0, uv);
    float ssao_factor = texture(colortex4, uv).r;

    // Do sky pixel check.
    float depth = texture(depthtex0, uv).r;
    if (depth == 1.0) {
        return;
    }

    // Get information from gbuffers.
    vec2 lightmap_uv = texture(colortex1, uv).xy;
    vec3 normal_world_space = texture(colortex2, uv).xyz * 2.0 - 1.0;
    #if POM == 1
    vec2 parallax_uv = texture(colortex5, uv).xy;
    #endif

    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 fragment_ndc_space_position = vec3(uv.xy, depth) * 2.0 - 1.0;
    vec3 fragment_view_space_position = ndc_to_view(fragment_ndc_space_position);
    vec3 fragment_feet_space_position = view_to_feet(fragment_view_space_position);
    vec3 shadow_view_space_position = (shadowModelView * vec4(fragment_feet_space_position, 1.0)).xyz;
    vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_view_space_position, 1.0);
    vec3 shadow = get_soft_shadow(shadow_clip_space_position, normal_world_space);

    // Sun/moon light source.
    vec3 fragment_world_space_position = feet_to_world(fragment_feet_space_position);
    vec3 light_source_world_space_position = feet_to_world(view_to_feet(shadowLightPosition));
    vec3 light_source_direction_world_space = normalize(light_source_world_space_position - fragment_world_space_position);
    float n_dot_l = compute_diffuse(light_source_direction_world_space, normal_world_space);

    float light_brightness = n_dot_l;

    #if SPECULAR_MAPPING == 1
    vec4 specular_data = texture(colortex3, uv);
    float perceptual_roughness = specular_data.r;
    float roughness = pow(1.0 - perceptual_roughness, 2.0);
    float smoothness = 1.0 - roughness;

    // https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model
    vec3 view_vector_world_space = fragment_world_space_position - cameraPosition;
    float r_dot_v = compute_specular(view_vector_world_space, light_source_direction_world_space, normal_world_space);
    float shininess = smoothness * 200.0 + 1.0; // alpha
    float specular_light_factor = smoothness * pow(r_dot_v, 4.0 * shininess);
    float diffuse_light_factor = roughness * n_dot_l;
    light_brightness = diffuse_light_factor + specular_light_factor;
    #endif

    float BLOCKLIGHT_INTENSITY = lightmap_uv.x, SKYLIGHT_INTENSITY = lightmap_uv.y;
    vec3 blocklight = BLOCKLIGHT_INTENSITY * BLOCKLIGHT_COLOR; // x is blocklight
    vec3 skylight = SKYLIGHT_INTENSITY * SKYLIGHT_COLOR; // y is skylight
    vec3 ambient = vec3(AMBIENT_INTENSITY * ssao_factor);
    // TODO: vary sunlight intensity by time of day.
    vec3 sunlight = light_brightness * shadow * lightmap_uv.y * SUNLIGHT_COLOR; // multiply by lightmap_uv to fix some light leaks.
    color.rgb *= blocklight + skylight + sunlight + ambient;

    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
