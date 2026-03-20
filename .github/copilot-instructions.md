# Fix SSAO.

Currently, when I display the SSAO values I calculate in @shaders/programs/composite/c0_ssao.glsl, I receive a completely black screen.

Your tasks:
- Review the file and look for obvious reasons my `occlusion_factor` might be rendered to the `colortex4` texture as 0.0.
- Find any other reason that when displaying `colortex4` to the screen, that it might just display black no matter the SSAO value.
