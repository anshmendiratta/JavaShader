use std::fs;
use std::io;
use std::path::{Path, PathBuf};

fn main() -> io::Result<()> {
    let base_path = PathBuf::from("../../shaders");
    let composite_src = base_path.join("programs/composite");
    let deferred_src = base_path.join("programs/deferred");
    let world0_dst = base_path.join("world0");

    // Create files for composite shaders
    process_shader_dir(&composite_src, &world0_dst, "composite", "composite")?;

    // Create files for deferred shaders
    process_shader_dir(&deferred_src, &world0_dst, "deferred", "deferred")?;

    println!("Shader files generated successfully!");
    Ok(())
}

fn process_shader_dir(
    src_dir: &Path,
    dst_dir: &Path,
    shader_type: &str,
    file_prefix: &str,
) -> io::Result<()> {
    let mut shader_files: Vec<PathBuf> = fs::read_dir(src_dir)?
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("glsl") {
                // Skip passthrough_composite.glsl for composite shaders
                if shader_type == "composite"
                    && path.file_name().and_then(|n| n.to_str())
                        == Some("passthrough_composite.glsl")
                {
                    return None;
                }
                Some(path)
            } else {
                None
            }
        })
        .collect();

    shader_files.sort();

    for (index, shader_path) in shader_files.iter().enumerate() {
        let shader_name = shader_path.file_name().unwrap().to_string_lossy();
        let include_path = format!("/programs/{}/{}", shader_type, shader_name);

        // Create .vsh file
        let vsh_filename = if index == 0 {
            format!("{}.vsh", file_prefix)
        } else {
            format!("{}{}.vsh", file_prefix, index)
        };
        let vsh_path = dst_dir.join(&vsh_filename);
        let vsh_content = create_vsh_content(&include_path);
        fs::write(&vsh_path, vsh_content)?;
        println!("Created: {}", vsh_filename);

        // Create .fsh file
        let fsh_filename = if index == 0 {
            format!("{}.fsh", file_prefix)
        } else {
            format!("{}{}.fsh", file_prefix, index)
        };
        let fsh_path = dst_dir.join(&fsh_filename);
        let fsh_content = create_fsh_content(&include_path);
        fs::write(&fsh_path, fsh_content)?;
        println!("Created: {}", fsh_filename);
    }

    Ok(())
}

fn create_vsh_content(include_path: &str) -> String {
    format!(
        "#version 430 compatibility\n\n#define STAGE_VERTEX\n#include \"{}\"\n",
        include_path
    )
}

fn create_fsh_content(include_path: &str) -> String {
    format!(
        "#version 430 compatibility\n\n#define STAGE_FRAGMENT\n#include \"{}\"\n",
        include_path
    )
}
