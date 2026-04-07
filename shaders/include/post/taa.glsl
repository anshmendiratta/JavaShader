#if !defined INCLUDE_POST_TAA
    #define INCLUDE_POST_TAA

    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/color/conversions.glsl"

    // ---------------------------------------------------------------
    //     Temporal Anti-Aliasing (TAA) Implementation
    // ---------------------------------------------------------------
    //
    // This TAA implementation uses temporal reprojection with:
    // - Motion vector calculation from previous frame matrices
    // - Neighborhood clamping (AABB) to reduce ghosting
    // - Adaptive blending based on disocclusion detection
    // - Proper handling of screen boundaries and sky pixels
    //
    // Usage in composite shader:
    //   vec3 taa_result = apply_taa(uv, current_color, history_texture, depth_texture);
    //
    // Requirements:
    // - History buffer (previous frame output)
    // - Depth buffer (depthtex0)
    // - Previous frame matrices (gbufferPreviousProjection, gbufferPreviousModelView)

    // Compute motion vector for current pixel by reprojecting to previous frame
    vec2 _compute_motion_vector(vec2 uv, float depth) {
        // Skip sky pixels (depth = 1.0 at far plane)
        if (depth >= 1.0) {
            return vec2(0.0);
        }

        // Screen space -> NDC space
        vec3 ndc_pos = screen_to_ndc(vec3(uv, depth));

        // NDC -> View space (current frame)
        vec3 view_pos = ndc_to_view(ndc_pos);

        // View -> Feet space (current frame)
        vec3 feet_pos = view_to_feet(view_pos);

        // Reproject to previous frame
        // Feet -> View space (previous frame)
        vec3 prev_view_pos = (gbufferPreviousModelView * vec4(feet_pos, 1.0)).xyz;

        // View -> Clip space (previous frame)
        vec4 prev_clip_pos = gbufferPreviousProjection * vec4(prev_view_pos, 1.0);

        // Clip -> NDC (previous frame)
        vec3 prev_ndc_pos = prev_clip_pos.xyz / prev_clip_pos.w;

        // NDC -> Screen space (previous frame)
        vec2 prev_uv = prev_ndc_pos.xy * 0.5 + 0.5;

        // Motion vector is the difference
        return uv - prev_uv;
    }

    // Sample 3x3 neighborhood for color clamping (reduces ghosting)
    void _sample_neighborhood_3x3(
    sampler2D color_texture,
    vec2 uv,
    out vec3 color_min,
    out vec3 color_max,
    out vec3 color_avg
    ) {
        vec3 neighborhood[9];
        int idx = 0;

        // Sample 3x3 neighborhood
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec2 offset = vec2(x, y) * texelSize;
                neighborhood[idx++] = texture(color_texture, uv + offset).rgb;
            }
        }

        // Compute min, max, and average
        color_min = neighborhood[0];
        color_max = neighborhood[0];
        color_avg = vec3(0.0);

        for (int i = 0; i < 9; i++) {
            color_min = min(color_min, neighborhood[i]);
            color_max = max(color_max, neighborhood[i]);
            color_avg += neighborhood[i];
        }

        color_avg /= 9.0;
    }

    // Optimized 5-tap cross neighborhood sampling (faster alternative)
    void _sample_neighborhood_cross(
    sampler2D color_texture,
    vec2 uv,
    out vec3 color_min,
    out vec3 color_max,
    out vec3 color_avg
    ) {
        vec3 center = texture(color_texture, uv).rgb;
        vec3 top = texture(color_texture, uv + vec2(0.0, 1.0) * texelSize).rgb;
        vec3 bottom = texture(color_texture, uv + vec2(0.0, -1.0) * texelSize).rgb;
        vec3 left = texture(color_texture, uv + vec2(-1.0, 0.0) * texelSize).rgb;
        vec3 right = texture(color_texture, uv + vec2(1.0, 0.0) * texelSize).rgb;

        color_min = min(center, min(min(top, bottom), min(left, right)));
        color_max = max(center, max(max(top, bottom), max(left, right)));
        color_avg = (center + top + bottom + left + right) * 0.2;
    }

    // AABB clamp with rounded corners (improves stability)
    vec3 clip_aabb(vec3 color_min, vec3 color_max, vec3 color_avg, vec3 history_color) {
        // Center the box around the average
        vec3 center = 0.5 * (color_max + color_min);
        vec3 extents = 0.5 * (color_max - color_min);

        // Offset from center
        vec3 offset = history_color - center;

        // Clip to AABB
        vec3 offset_sign = sign(offset);
        vec3 offset_abs = abs(offset);
        vec3 t_intersect = (extents - EPSILON) / max(offset_abs, vec3(EPSILON));
        float t = min(min(t_intersect.x, t_intersect.y), t_intersect.z);

        if (t < 1.0) {
            return center + offset * clamp01(t);
        }

        return history_color;
    }

    // Simplified box clamp (faster)
    vec3 clamp_aabb(vec3 color_min, vec3 color_max, vec3 history_color) {
        return clamp(history_color, color_min, color_max);
    }

    // Apply Temporal Anti-Aliasing
    // Parameters:
    //   uv             : Current pixel UV coordinates
    //   current_color  : Current frame color at this pixel
    //   history_texture: Sampler containing previous frame's output
    //   depth_texture  : Depth buffer (depthtex0)
    //   blend_factor   : Base blend factor (0.05-0.15 typical, lower = more temporal stability)
    //   use_clipping   : Use rounded AABB clipping (true) or simple clamping (false)
    vec3 apply_taa(
    vec2 uv,
    vec3 current_color,
    sampler2D history_texture,
    sampler2D depth_texture,
    float blend_factor,
    bool use_clipping
    ) {
        // Sample depth
        float depth = texture(depth_texture, uv).r;

        // Skip TAA for sky pixels (no temporal coherence at far plane)
        if (depth >= 1.0) {
            return current_color;
        }

        // Compute motion vector
        vec2 motion = _compute_motion_vector(uv, depth);
        vec2 prev_uv = uv - motion;

        // Check if reprojected coordinate is off-screen (disocclusion)
        bool is_offscreen = any(lessThan(prev_uv, vec2(0.0))) ||
                any(greaterThan(prev_uv, vec2(1.0)));

        // If off-screen, use current frame only (no history available)
        if (is_offscreen) {
            return current_color;
        }

        // Sample history color
        vec3 history_color = texture(history_texture, prev_uv).rgb;

        // Sample neighborhood for clamping
        vec3 color_min, color_max, color_avg;
        _sample_neighborhood_cross(colortex0, uv, color_min, color_max, color_avg);

        // Clamp or clip history to neighborhood AABB
        vec3 clamped_history;
        if (use_clipping) {
            clamped_history = clip_aabb(color_min, color_max, color_avg, history_color);
        } else {
            clamped_history = clamp_aabb(color_min, color_max, history_color);
        }

        // Compute adaptive blend factor based on disocclusion confidence
        float confidence = 1.0;

        // Reduce confidence if history was clamped significantly
        float clamp_amount = length(clamped_history - history_color);
        confidence *= exp(-clamp_amount * 10.0);

        // Reduce confidence based on motion magnitude (high motion = less trust in history)
        float motion_magnitude = length(motion * vec2(viewWidth, viewHeight));
        confidence *= exp(-motion_magnitude * 0.1);

        // Adaptive blend factor (higher confidence = more history weight)
        float adaptive_blend = mix(0.5, blend_factor, confidence);

        // Blend current and history
        vec3 result = mix(clamped_history, current_color, adaptive_blend);

        return result;
    }

    // Simplified TAA with default parameters
    vec3 apply_taa_simple(
    vec2 uv,
    vec3 current_color,
    sampler2D history_texture,
    sampler2D depth_texture
    ) {
        return apply_taa(uv, current_color, history_texture, depth_texture, 0.1, false);
    }

    // High-quality TAA with clipping
    vec3 apply_taa_high_quality(
    vec2 uv,
    vec3 current_color,
    sampler2D history_texture,
    sampler2D depth_texture
    ) {
        return apply_taa(uv, current_color, history_texture, depth_texture, 0.07, true);
    }

#endif
