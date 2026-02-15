#!/home/linuxbrew/.linuxbrew/bin/fish

set SHADERPACKS_DIR /opt/prismlauncher/instances/Shader/minecraft/shaderpacks

if test -e $SHADERPACKS_DIR/shaderpack.zip
    rm $SHADERPACKS_DIR/shaderpack.zip
    set_color red
    echo "Removed existing shader."
end

zip -r -q shaderpack.zip shaders
if test $status -eq 0
    set_color blue
    echo "Rezipped shader."
end

ln shaderpack.zip $SHADERPACKS_DIR/
if test $status -eq 0
    set_color -o green
    echo "Reset shader."
else
    set_color -o red
    echo "Unsuccessful resetting shader."
end
