const int shadowMapResolution = 2048; // Increases VRAM usage as well as compute cost.

vec3 distort_shadow_clip_space_position(vec3 position) {
	float distortion_factor = length(position.xy); // Shadow clip space (xy) is the light source looking at the player (so they are the origin (0, 0)). Since there is no perspective in clip space, the distance from the player of the point (x', y') is the smae in all directions, making this method work.
	distortion_factor += 0.1; // Some bugs arise when the distances are tiny, so we increment this a bit.
	position.xy /= distortion_factor; // Apply distortion.
	position.z *= 0.5; // The origin (x, y, z) = (0, 0, 0) in clip space is the light source, so we don't apply the distortion if the arrow digs into or comes out of the screen. Instead, this value lets you control how far the shadows can stretch -- the default is 256 blocks, so halving this value lets you fit 512 blocks worth of shadow when you undo this operation.

	return position;
}


