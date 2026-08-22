#if !defined INCLUDE_SKY_COLOR
    #define INCLUDE_SKY_COLOR

    // #if !defined STAGE_COMPUTE
        #include "/include/uniforms.glsl"
    // #endif
    #include "/include/settings.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/utility/phase_functions.glsl"

    #define MAGIC_FOG_VALUE 0.08 // taken from shrimple v2: https://github.com/Null-MC/Shrimple/blob/f4fcab627cc62bd2e66813c58cd657bb4ecbb84f/shaders/lib/fog/fog_common.glsl#L1

    // ---------------
    //     Utility
    // ---------------

    // Units are in megameters.
    const float groundRadiusMM = 6.360;
    const float atmosphereRadiusMM = 6.460;

    // 200M above the ground.
    const vec3 viewPos = vec3(0.0, groundRadiusMM + 0.0002, 0.0);

    const vec2 tLUTRes = vec2(256.0, 64.0);
    const vec2 msLUTRes = vec2(32.0, 32.0);
    // Doubled the vertical skyLUT res from the paper, looks way
    // better for sunrise.
    const vec2 skyLUTRes = vec2(200.0, 200.0);

    const vec3 groundAlbedo = vec3(0.3);

    // These are per megameter.
    const vec3 rayleighScatteringBase = vec3(5.802, 13.558, 33.1);
    const float rayleighAbsorptionBase = 0.0;

    const float mieScatteringBase = 3.996;
    const float mieAbsorptionBase = 4.4;

    const vec3 ozoneAbsorptionBase = vec3(0.650, 1.881, .085);

    float getSunAltitude(float time)
    {
        const float periodSec = 120.0;
        const float halfPeriod = periodSec / 2.0;
        const float sunriseShift = 0.1;
        float cyclePoint = (1.0 - abs((mod(time, periodSec) - halfPeriod) / halfPeriod));
        cyclePoint = (cyclePoint * (1.0 + sunriseShift)) - sunriseShift;
        return (0.5 * PI) * cyclePoint;
    }
    vec3 getSunDir(float time)
    {
        float altitude = getSunAltitude(time);
        return normalize(vec3(0.0, sin(altitude), -cos(altitude)));
    }

    float getMiePhase(float cosTheta) {
        const float g = 0.8;
        const float scale = 3.0 / (8.0 * PI);

        float num = (1.0 - g * g) * (1.0 + cosTheta * cosTheta);
        float denom = (2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * cosTheta, 1.5);

        return scale * num / denom;
    }

    float getRayleighPhase(float cosTheta) {
        const float k = 3.0 / (16.0 * PI);
        return k * (1.0 + cosTheta * cosTheta);
    }

    void getScatteringValues(vec3 pos,
    out vec3 rayleighScattering,
    out float mieScattering,
    out vec3 extinction) {
        float altitudeKM = (length(pos) - groundRadiusMM) * 1000.0;
        // Note: Paper gets these switched up.
        float rayleighDensity = exp(-altitudeKM / 8.0);
        float mieDensity = exp(-altitudeKM / 1.2);

        rayleighScattering = rayleighScatteringBase * rayleighDensity;
        float rayleighAbsorption = rayleighAbsorptionBase * rayleighDensity;

        mieScattering = mieScatteringBase * mieDensity;
        float mieAbsorption = mieAbsorptionBase * mieDensity;

        vec3 ozoneAbsorption = ozoneAbsorptionBase * max(0.0, 1.0 - abs(altitudeKM - 25.0) / 15.0);

        extinction = rayleighScattering + rayleighAbsorption + mieScattering + mieAbsorption + ozoneAbsorption;
    }

    float safeacos(const float x) {
        return acos(clamp(x, -1.0, 1.0));
    }

    // From https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
    float rayIntersectSphere(vec3 ro, vec3 rd, float rad) {
        float b = dot(ro, rd);
        float c = dot(ro, ro) - rad * rad;
        if (c > 0.0f && b > 0.0) return -1.0;
        float discr = b * b - c;
        if (discr < 0.0) return -1.0;
        // Special case: inside sphere, use far discriminant
        if (discr > b * b) return (-b + sqrt(discr));
        return -b - sqrt(discr);
    }

    vec3 getValFromTLUT(sampler2D tex, vec2 bufferRes, vec3 pos, vec3 sunDir) {
        float height = length(pos);
        vec3 up = pos / height;
        float sunCosZenithAngle = dot(sunDir, up);
        vec2 uv = vec2(tLUTRes.x * clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
                tLUTRes.y * max(0.0, min(1.0, (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM))));
        uv /= bufferRes;
        return texture(tex, uv).rgb;
    }
    vec3 getValFromMultiScattLUT(sampler2D tex, vec2 bufferRes, vec3 pos, vec3 sunDir) {
        float height = length(pos);
        vec3 up = pos / height;
        float sunCosZenithAngle = dot(sunDir, up);
        vec2 uv = vec2(msLUTRes.x * clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
                msLUTRes.y * max(0.0, min(1.0, (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM))));
        uv /= bufferRes;
        return texture(tex, uv).rgb;
    }

    const float sunRadius = 6.9634e8;
    const float sunDistance = 1.496e11;
    const float sunAngularRadius = sunRadius / sunDistance;
    const float sunSolidAngle = TAU * (1.0 - cos(sunAngularRadius));
    const vec3 sunLuminance = vec3(1.6e9);
    const vec3 sunIlluminance = sunLuminance * sunSolidAngle;

    vec3 atmospherePos = vec3(0.0, groundRadiusMM + (cameraPosition.y + 5000) * 1e-6, 0.0);

    #if !defined STAGE_COMPUTE
        vec3 getValFromSkyLUT(vec3 rayDir) {
            float height = atmospherePos.y;
            vec3 up = vec3(0.0, 1.0, 0.0);

            float horizonAngle = safeacos(
                    sqrt(height * height - groundRadiusMM * groundRadiusMM) / height
                );
            float altitudeAngle = horizonAngle - acos(dot(rayDir, up)); // Between -PI/2 and PI/2
            float azimuthAngle; // Between 0 and 2*PI
            if (abs(altitudeAngle) > 0.5 * PI - 0.0001) {
                // Looking nearly straight up or down.
                azimuthAngle = 0.0;
            } else {
                vec3 right = vec3(1.0, 0.0, 0.0);
                vec3 forward = vec3(0.0, 0.0, -1.0);

                vec3 projectedDir = normalize(rayDir - up * dot(rayDir, up));
                float sinTheta = dot(projectedDir, right);
                float cosTheta = dot(projectedDir, forward);
                azimuthAngle = atan(sinTheta, cosTheta) + PI;
            }

            // Non-linear mapping of altitude angle. See Section 5.3 of the paper.
            float v = 0.5 + 0.5 * sign(altitudeAngle) * sqrt(abs(altitudeAngle) * 2.0 / PI);
            vec2 uv = vec2(azimuthAngle / (2.0 * PI), v);

            return textureLod(skyview_lut, uv, 0).rgb;
        }

        vec3 getSky(vec3 dir, bool includeSun) {
            vec3 transmittance = getValFromTLUT(
                    transmittance_lut,
                    tLUTRes,
                    atmospherePos,
                    dir
                );
            vec3 sky = getValFromSkyLUT(dir);

            if (includeSun) {
                if (dot(dir, light_dir) > cos(sunAngularRadius)) {
                    sky += sunLuminance * transmittance;
                }
            }

            return sky;
        }
    #endif

    // ---------------
    //     PBR Sky
    // ---------------
    // implements Bruneton's 2017 revision

    const float ATM_RAYLEIGH_SCALE = 8e3; // meters
    const float ATM_MIE_SCALE = 1.2e3; // meters

    // -------------------
    //     Vanilla sky
    // -------------------

    float _fogify(float x, float w) {
        return w / (x * x + w);
    }

    // returns in linear space
    vec3 get_sky_color(in vec3 sky_color, in vec3 fog_color, in float up_factor) {
        float fogified_factor = _fogify(up_factor, MAGIC_FOG_VALUE);
        return oklab_mix(sky_color, fog_color, fogified_factor);
    }
#endif
