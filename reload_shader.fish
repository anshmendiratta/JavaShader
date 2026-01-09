#!/home/linuxbrew/.linuxbrew/bin/fish

set OS_IS_LINUX_MINT bash -c "cat /etc/os-release | head -n 1 | grep -q -e 'Linux Mint'"
# Determine shaderpack dir.
if $OS_IS_LINUX_MINT -eq 0
    set SHADERPACKS_DIR /opt/PrismLauncher/instances/Shader/minecraft/shaderpacks
else
    set SHADERPACKS_DIR "/home/asahi/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Shader/minecraft/shaderpacks"
end

# Remove existing links/zips.
if test -L $SHADERPACKS_DIR/shaders
    rm -r $SHADERPACKS_DIR/shaders
end
if test -e $SHADERPACKS_DIR/shader.zip
    rm $SHADERPACKS_DIR/shader.zip
end

zip -r shader.zip shaders
ln -t $SHADERPACKS_DIR/ shader.zip

# Print on success.
if test $status -eq 0
    echo "Reset shader."
else
    echo "Unsuccessful."
end
