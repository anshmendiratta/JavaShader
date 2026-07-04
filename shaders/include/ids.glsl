#if !defined INCLUDE_IDS
    #define INCLUDE_IDS

    // -------------------------------
    //     Aliases for mc_Entity.x
    // -------------------------------

    #define ID_ROOTED_FOLIAGE 10000.0
    #define ID_FREE_FOLIAGE 10001.0

    #define ID_WATER 10002.0

    // ------------------------------
    //     Ranges for mc_Entity.x
    // ------------------------------

    #define _construct_vec(dim)  void _construct_vec(in const uint dimension, in const float value, out float[dim##] vector) { for (uint idx = 0; idx < dimension; idx += 1) { vector[idx] = value; } }
    _construct_vec(2);
    _construct_vec(3);
    _construct_vec(4);
    _construct_vec(5);
    _construct_vec(6);
    _construct_vec(7);
    _construct_vec(8);
    _construct_vec(9);
    _construct_vec(10);
    _construct_vec(11);
    _construct_vec(12);
    _construct_vec(13);
    _construct_vec(14);
    _construct_vec(15);
    _construct_vec(16);
    _construct_vec(17);
    _construct_vec(18);
    _construct_vec(19);
    _construct_vec(20);
    #undef _construct_vec

    const uint SSR_MATERIALS = 6;
    const float[SSR_MATERIALS] ID_SSR = {
            11000.0,
            11001.0,
            11002.0,
            11003.0,
            11004.0,
            11005.0
    };

    // bool should_get_ssr(float id) {
    //     float[SSR_MATERIALS] _ids;
    //     _construct_vec(SSR_MATERIALS, id, _ids);
    //     return any(equal(_ids, ID_SSR));
    // }
#endif
