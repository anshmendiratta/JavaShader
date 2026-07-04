#ifdef STAGE_VERTEX
out vec2 uv;

void main() {
    gl_Position = ftransform();
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif

#ifdef STAGE_FRAGMENT
in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/include/uniforms.glsl"

#include "/include/pbr/material.glsl"

#include "/include/sky/color.glsl"

#include "/include/color/conversions.glsl"

#include "/include/lighting/ssr.glsl"

#include "/include/shadows/compute.glsl"

#include "/include/utility/space_conversions.glsl"
#include "/include/utility/depth_conversion.glsl"
#include "/include/utility/dither.glsl"

// TODO: implement a PBR sky with clouds so i can reflect them properly

void main() {
    color = texture(colortex0, uv);

    if (fragment_is_hand(uv) || texture(depthtex0, uv).r == 1.0)
        return; // don't reflect hand or sky

    Material material;
    init_material_unpacked_colortex_read(material);

    // NOTE: cant use `screen_uv` here
    vec3 frag_position_screen = vec3(uv, texture(depthtex0, uv).r);
    vec3 frag_position_view = screen_to_view(frag_position_screen);
    vec3 frag_position_world = view_to_world(frag_position_view);

    vec3 frag_view_vector_view = -normalize(frag_position_view);
    vec3 frag_view_vector_world = mat3(gbufferModelViewInverse) * frag_view_vector_view;
    vec3 frag_normal_view = normalize(mat3(gbufferModelView) * material.normal);
    vec3 frag_reflected_ray_view = reflect(-frag_view_vector_view, frag_normal_view); // TODO: why tf does this need a negative. the view vector already points out from the fragment?

    vec3 fresnel = vec3(1.0, 0.0, 0.0); // debug-able fallback if something fails
    if (material.block_id == ID_WATER) {
        fresnel = _fresnel_schlick(material, dot(frag_view_vector_world, material.normal));
    } else {
        vec3 light_source_vector_world = normalize(mat3(gbufferModelViewInverse) * worldLightVector);
        vec3 halfway_vector_world = normalize(light_source_vector_world + frag_view_vector_world);

        fresnel = material.is_metal ?
            vec3(1.0) :
            // _fresnel_rescaled_schlick(material, dot(halfway_vector_world, light_source_vector_world)) :
            _fresnel_schlick(material, dot(halfway_vector_world, light_source_vector_world));
    }

    vec2 reflected_uv;
    bool hit_ssr_object = raymarch_ssr(material, fresnel, uv, reflected_uv, frag_position_view, frag_reflected_ray_view);
    vec3 reflected_uv_screen = vec3(reflected_uv, texture(depthtex0, reflected_uv).r);
    vec3 reflected_uv_view = screen_to_view(reflected_uv_screen);
    vec3 reflected_uv_world = mat3(gbufferModelViewInverse) * normalize(reflected_uv_view);

    vec3 reflected_color = texture(colortex0, reflected_uv).rgb;
    // sample sky if no hit and (probably) hit sky if it could
    // if (!hit_ssr_object && (mat3(gbufferModelViewInverse) * frag_reflected_ray_view).y > 0.0) {
    if (!hit_ssr_object) { // NOTE: removed the above secondary condition so that streaking is less common
        vec3 skydome_position_view = frag_position_view + 10000. * normalize(frag_reflected_ray_view); // TODO: not sure if this is ideal.
        reflected_color = get_pbr_sky_color(skydome_position_view);
    }
    // TODO: figure out a better fadeoff for this
    // float reflection_fadeoff = max(1.0 - rcp(0.5) * avg_vec(abs(reflected_uv - uv)), 0.0) /* based on distance between uv and reflected uv */ ;
    // float reflection_fadeoff = clamp01(length(frag_position_world - reflected_uv_world) / far);

    // TODO: gold reflects blue
    if (material.is_metal) reflected_color *= material.albedo;

    // dont reflect sky if shadowed
    // vec3 frag_position_shadow_screen = shadow_clip_to_shadow_screen(shadow_view_to_shadow_clip(feet_to_shadow_view(view_to_feet(frag_position_view))));
    // float is_shadowed = float(_frag_is_shadowed(frag_position_shadow_screen));

    // color.rgb = fresnel; // TODO: the glass panes in a glass block are completely see-through. bliss does not have this problem
    color.rgb = oklab_mix(color.rgb, reflected_color, SSR_VISIBILITY * fresnel);
}
#endif
