#if !defined INCLUDE_PHOTONICS_INTERFACE
    #define INCLUDE_PHOTONICS_INTERFACE

    #include "/include/ids.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/utility/space_conversions.glsl"

    #include "/include/pbr/textures.glsl"
    #include "/include/pbr/hcm.glsl"
    // #include "/include/pbr/material.glsl"

    vec3 sun_direction = light_dir;
    vec3 indirect_light_color = skyColor;

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
        uint block_id;
        uint metal_id;
        vec2 lightmap_uv;
    };
    void init_material_raw_read(inout Material material, in const vec2 uv, in const mat3 TBN) {
        material.albedo = texture(gtexture, uv).rgb;
        vec4 normal_data = texture(normals, uv);
        vec4 specular_data = texture(specular, uv);

        material.ao = normal_data.b;
        material.depth = normal_data.a;

        // specular map
        material.roughness = pow2(1. - specular_data.r);
        material.porosity = (specular_data.b <= 64. / 255.) ? (specular_data.b * 255. / 64.) : 0.;
        material.sss = (specular_data.b >= 65. / 255.) ? (specular_data.b - 65. / 255.) / (1. - 64. / 255.) : 0.;
        material.emissiveness = fract(specular_data.a); // since 0 and 255 are no emission

        // hardcode water
        if (material.block_id == ID_WATER) {
            material.f0 = vec3(0.02); // value from axolotan
            material.roughness = rcp(255.);
            material.is_metal = false;
            material.metal_id = 0u;

            // normal
            vec3 frag_pos_screen = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z);
            vec3 frag_pos_view = screen_to_view(frag_pos_screen);
            vec3 frag_pos_world = view_to_world(frag_pos_view);
            material.normal = compute_water_normal(frag_pos_world);

            return;
        }

        // normal map
        normal_data.xy = normal_data.xy * 2. - 1.;
        material.normal = vec3(normal_data.xy, sqrt(1. - dot(normal_data.xy, normal_data.xy))); // normal space
        material.normal = mat3(gbufferModelViewInverse) * (TBN * material.normal); // world space

        // handle hcm
        material.is_metal = (specular_data.g >= 230. / 255.);
        if (material.is_metal) {
            // treat everything as a vanilla metal. even modded ones
            const uint metal_id = clamp(uint(255. * specular_data.g) - 230, 0, 7);
            material.f0 = compute_hcm_f0(metal_id);
            material.metal_id = metal_id;
        } else {
            if (specular_data.g < rcp(255.)) {
                material.f0 = vec3(0.0); // default if no value given
            } else {
                material.f0 = vec3(specular_data.g);
            }
        }
    }

    vec3 load_world_position() {
        vec3 screen_uv = vec3(gl_FragCoord.xy / windowDimensions, gl_FragCoord.z);
        vec3 frag_pos_view = screen_to_view(screen_uv);

        return view_to_world(frag_pos_view);
    }

    void load_fragment_variables(out vec3 albedo, out vec3 world_pos, out vec3 geometry_normal, out vec3 texture_normal) {
        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;

        geometry_normal = texture(colortex3, screen_uv).xyz * 2. - 1.; // vert normal

        const mat3 TBN = get_tbn_matrix(mat3(gbufferModelView) * geometry_normal);
        Material m;
        init_material_raw_read(m, screen_uv, TBN);

        texture_normal = m.normal;
        albedo = m.albedo;
        world_pos = load_world_position() - 0.01 * geometry_normal;
    }

    vec2 get_taa_jitter() {
        return vec2(0.);
    }

    bool is_in_world() {
        return texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x <= 0.99999f;
    }
#endif
