#!/home/linuxbrew/.linuxbrew/bin/fish

set OS_IS_LINUX_MINT bash -c "cat /etc/os-release | head -n 1 | grep -q -e 'Linux Mint'"
rm shader.zip
zip -r shader.zip shaders/

if $OS_IS_LINUX_MINT -eq 0
    set SHADERPACKS_DIR "/home/mintdesktop/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Shader/minecraft/shaderpacks"
else
    set SHADERPACKS_DIR "/home/asahi/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Shader/minecraft/shaderpacks"
end
rm $SHADERPACKS_DIR/shader.zip
ln shader.zip $SHADERPACKS_DIR/

echo "Reset shader."
