#if !defined INCLUDE_MATH_ARCANE
    #define INCLUDE_MATH_ARCANE

    // ------------------
    //     Prototypes
    // ------------------

    float erfinv(float x);

    // ------------------------------------
    //     Normal distribution sampling
    // ------------------------------------
    // from: https://gpuopen.com/learn/sampling-normal-gaussian-distribution-gpus/

    float sampleNormalDistributionInvCDF(float u, float mean, float standardDeviation) {
        return mean + SQRT_TWO * standardDeviation * erfinv(2.0f * u - 1.0f);
    }

    float erfinv(float x) {
        float tt1, tt2, lnx, sgn;
        sgn = (x < 0.0f) ? -1.0f : 1.0f;
        x = (1.0f - x) * (1.0f + x);
        lnx = log(x);
        tt1 = 2.0f / (3.14159265359f * 0.147f) + 0.5f * lnx;
        tt2 = 1.0f / (0.147f) * lnx;

        return (sgn * sqrt(-tt1 + sqrt(tt1 * tt1 - tt2)));
    }
#endif