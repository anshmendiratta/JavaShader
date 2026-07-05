#if !defined INCLUDE_MATERIAL
#define INCLUDE_MATERIAL

#include "/include/ids.glsl"
#include "/include/uniforms.glsl"

#include "/include/utility/bits.glsl"
#include "/include/utility/space_conversions.glsl"

#include "/include/pbr/hcm.glsl"
#include "/include/pbr/textures.glsl"

// ------------------
//     Primitives
// ------------------

struct Material {
    // pbr
    float ao;
    float depth;
    float roughness;
    float porosity;
    float sss; // subsurface scattering
    float emissiveness;
    vec3 albedo;
    vec3 normal; // world space
    vec3 f0; // reflectance.

    // flags. some taken from photon
    bool is_metal; // default: false

    // general
    float block_id;
    uint metal_id;
    vec2 lightmap_uv;
};

/// ------------------
///     Prototypes
/// ------------------

vec3 _fresnel_phong(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world);
vec3 _fresnel_schlick(in const Material material, in const float dot_prod);
vec3 _fresnel_rescaled_schlick(in const Material material, in const float dot_prod);

/// --------------------
///     Texture reads
/// --------------------

// NOTE: lightmap_uv and block_id need to be filled in manually before using this function
void init_material_raw_read(inout Material material, in const vec2 uv, in const mat3 TBN) {
    material.albedo = texture(gtexture, uv).rgb;

    // normal map
    vec4 normal_data = texture(normals, uv);
    normal_data.xy = normal_data.xy * 2. - 1.;
    material.normal = vec3(normal_data.xy, sqrt(1. - dot(normal_data.xy, normal_data.xy))); // normal space
    material.normal = mat3(gbufferModelViewInverse) * (TBN * material.normal); // world space

    material.ao = normal_data.b;
    material.depth = normal_data.a;

    // specular map
    vec4 specular_data = texture(specular, uv);
    material.roughness = pow2(1. - specular_data.r);
    material.porosity = (specular_data.b <= 64. / 255.) ? (specular_data.b * 255. / 64.) : 0.;
    material.sss = (specular_data.b >= 65. / 255.) ? (specular_data.b - 65. / 255.) / (1. - 64. / 255.) : 0.;
    material.emissiveness = fract(specular_data.a); // since 0 and 255 are no emission

    // handle hcm
    material.is_metal = (specular_data.g >= 230. / 255.);
    if (material.is_metal) {
        // treat everything as a vanilla metal. even modded ones
        const uint metal_id = clamp(uint(255. * specular_data.g) - 230, 0, 7);
        material.f0 = compute_hcm_f0(metal_id);
        material.metal_id = metal_id;
    } else {
        if (specular_data.g < rcp(255.)) {
            material.f0 = vec3(0.4); // default if no value given
        } else {
            material.f0 = vec3(specular_data.g);
        }
    }

    // hardcode water
    if (material.block_id == ID_WATER) {
        material.f0 = vec3(0.02); // value from axolotan
        material.roughness = rcp(255.);
        material.is_metal = false;
    }
}

void init_material_unpacked_colortex_read(out Material material) {
    float block_id;
    vec2 lightmap_uv;
    vec4 normal_map_read, specular_map_read;
    unpack_colortex1_read(texture(colortex1, uv), normal_map_read, specular_map_read, lightmap_uv, block_id);

    material.albedo = texture(gtexture, uv).rgb;
    material.block_id = block_id;
    material.lightmap_uv = lightmap_uv;

    vec2 octahedral_encoded_normal = normal_map_read.xy * 2. - 1.;
    vec3 normal_world = vector_decode_octahedral(octahedral_encoded_normal);
    material.normal = vec3(normal_world);

    material.ao = normal_map_read.b;
    material.depth = normal_map_read.a;
    material.roughness = pow2(1. - specular_map_read.r);
    material.porosity = (specular_map_read.b <= 64. / 255.) ? (specular_map_read.b * 255. / 64.) : 0.;
    material.sss = (specular_map_read.b >= 65. / 255.) ? (specular_map_read.b - 65. / 255.) / (1. - 64. / 255.) : 0.;
    material.emissiveness = fract(specular_map_read.a);

    material.is_metal = (specular_map_read.g >= 230. / 255.);
    if (material.is_metal) {
        // treat everything as a vanilla metal. even modded ones
        const uint metal_id = clamp(uint(255. * specular_map_read.g) - 230, 0, 7);
        material.f0 = compute_hcm_f0(metal_id);
        material.metal_id = metal_id;
    } else {
        if (specular_map_read.g < rcp(255.)) {
            material.f0 = vec3(0.4); // default if no value given
        } else {
            material.f0 = vec3(specular_map_read.g);
        }
        material.metal_id = 0;
    }

    // hardcode water
    if (material.block_id == ID_WATER) {
        material.f0 = vec3(0.02); // value from axolotan
        material.roughness = rcp(255.);
        material.is_metal = false;
    }
}

// ------------------------------
//     Fresnel approximations
// ------------------------------

// all of the below are approximations of reflectance (the amount of reflected light) where `fresnel` is calculated _exactly_ using fresnel's equations

vec3 _fresnel_phong(in const Material material, in const vec3 view_vector_world, in const vec3 light_source_vector_world) {
    vec3 halfway_vector_world = normalize(view_vector_world + light_source_vector_world);

    return vec3(clamp01(dot(material.normal, halfway_vector_world)));
}

vec3 _fresnel_schlick(in const Material material, in const float dot_prod) {
    return clamp01(material.f0 + (1. - material.f0) * pow5(1. - clamp01(dot_prod)));
}

// https://naos-be.zcu.cz/server/api/core/bitstreams/c2d8b0a7-9947-4458-98e3-d3f8df920153/content
vec3 _fresnel_rescaled_schlick(in const Material material, in const float dot_prod) {
    if (material.metal_id == 99) return vec3(1., 0., 0.);

    vec3 n = hcm_ior[material.metal_id];
    vec3 k = hcm_ext[material.metal_id];

    vec3 numerator = pow2(n - 1) + 4 * n * pow5(1 - clamp01(dot_prod)) + pow2(k);
    vec3 denominator = pow2(n + 1) + pow2(k);

    return clamp01(numerator / denominator);
}
#endif
