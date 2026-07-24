// #include "/include/uniforms.glsl"

#include "/include/pbr/atmosphere.glsl"

// layout(local_size_x = 8, local_size_y = 8) in;
// const ivec3 workGroups = ivec3(64, 1, 1);
layout(local_size_x = 8, local_size_y = 8) in;
const ivec3 workGroups = ivec3(32, 8, 1);

layout(rgba16f) uniform image2D transmittance_lut;

const float sunTransmittanceSteps = 40.0;

vec3 getSunTransmittance(vec3 pos, vec3 sunDir) {
    if (rayIntersectSphere(pos, sunDir, groundRadiusMM) > 0.0) {
        return vec3(0.0);
    }

    float atmoDist = rayIntersectSphere(pos, sunDir, atmosphereRadiusMM);
    float t = 0.0;

    vec3 transmittance = vec3(1.0);
    for (float i = 0.0; i < sunTransmittanceSteps; i += 1.0) {
        float newT = ((i + 0.3) / sunTransmittanceSteps) * atmoDist;
        float dt = newT - t;
        t = newT;

        vec3 newPos = pos + t * sunDir;

        vec3 rayleighScattering, extinction;
        float mieScattering;
        getScatteringValues(newPos, rayleighScattering, mieScattering, extinction);

        transmittance *= exp(-dt * extinction);
    }
    return transmittance;
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    float u = clamp(uv.x, 0.0, tLUTRes.x - 1.0) / tLUTRes.x;
    float v = clamp(uv.y, 0.0, tLUTRes.y - 1.0) / tLUTRes.y;

    float sunCosTheta = 2.0 * u - 1.0;
    float sunTheta = safeacos(sunCosTheta);
    float height = mix(groundRadiusMM, atmosphereRadiusMM, v);

    vec3 pos = vec3(0.0, height, 0.0);
    vec3 sunDir = normalize(vec3(0.0, sunCosTheta, -sin(sunTheta)));

    imageStore(
        transmittance_lut,
        uv,
        vec4(getSunTransmittance(pos, sunDir), 1.0)
    );
}
