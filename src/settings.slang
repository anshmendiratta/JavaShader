public module settings;

extern static const bool value_shadow_toggle;

struct Settings {
    static const bool shadows = value_shadow_toggle;
};

ConstantBuffer<Settings, ScalarDataLayout> userSettings;