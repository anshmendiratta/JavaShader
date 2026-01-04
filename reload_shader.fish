#!/home/linuxbrew/.linuxbrew/bin/fish

set OS_IS_LINUX_MINT bash -c "cat /etc/os-release | head -n 1 | grep -q -e 'Linux Mint'"
if $OS_IS_LINUX_MINT -eq 0
    # Desktop.
    rm shader.zip
    zip -r shader.zip shaders/

    set SHADERPACKS_DIR "/home/mintdesktop/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Shader/minecraft/shaderpacks"
    rm $SHADERPACKS_DIR/shader.zip
    ln shader.zip $SHADERPACKS_DIR/
else
    # Asahi.
end
