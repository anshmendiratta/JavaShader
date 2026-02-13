# #!/bin/bash
# 
# Courtesy of @gri573 (https://discord.com/channels/237199950235041794/525510804494221312/1391452518038376611) from the shaderLABS discord.
# ---
# Usage: moveprogram.sh <old_program> <new_program> [dryrun]


if [ "$1" == "" ] || [ "$2" == "" ]
then
    echo "Usage: moveprogram.sh <old_program_name> <new_program_name>" >&2
    exit 1
fi
DEST_PRE_FILES=$(find . -name $2*)
if [ "$DEST_PRE_FILES" != "" ]
then
    echo "$2 seems to exist already (found the following files):
$DEST_PRE_FILES

Continuing is very likely to break your shader!
Do you really want to do this? [y/N]"
    read RESPONSE
    if [ "$RESPONSE" != "y" ] && [ "$RESPONSE" != "Y" ]
    then
	exit 1
    fi
fi

for F in $(find shaders -name "$1*")
do
    NEWNAME=$(echo $F | sed "s/$1/$2/")
    while [ -f $NEWNAME ]
    do
	printf "Would move $F to $NEWNAME, which already exists!
Please enter alternative filename: "
	read NEWNAME
	if [ $(echo $NEWNAME | sed 's/^([.]\/)?shaders\///') == $NEWNAME ]
	then
	    NEWNAME=shaders/$NEWNAME
	fi
    done
    MOVEMENTRULES="$MOVEMENTRULES$F:$NEWNAME
"
done

OLDPROGDEF=$(echo $1 | tr [:lower:] [:upper:])
NEWPROGDEF=$(echo $2 | tr [:lower:] [:upper:])

for F in $(grep shaders --recursive --files-with-matches -F -e $OLDPROGDEF)
do
    echo "changing program define from $OLDPROGDEF to $NEWPROGDEF in $F"
    if [ "$3" != "dryrun" ]
    then
	sed -i -e "s/$OLDPROGDEF/$NEWPROGDEF/" $F
    fi
done

for RULE in $MOVEMENTRULES
do
    OLDFILE=$(echo $RULE | sed 's/:.*//')
    NEWFILE=$(echo $RULE | sed 's/.*://')
    echo "moving $OLDFILE to $NEWFILE"
    if [ "$3" != "dryrun" ]
    then
	mv $OLDFILE $NEWFILE
    fi
    OLDTRUNCPATH=$(echo $OLDFILE | sed -E 's/^([.]\/)?shaders//')
    ESCAPEDNEWTRUNCPATH=$(echo $NEWFILE | sed -E 's/^([.]\/)?shaders//;s/\//\\\//g')
    ESCAPEDOLDTRUNCPATH=$(echo $OLDTRUNCPATH | sed -E ';s/\//\\\//g;s/[.]/[.]/g')
    for F in $(grep shaders --recursive --files-with-matches -F -e "#include \"$OLDTRUNCPATH\"")
    do
	echo "replacing include destination $OLDFILE with $NEWFILE in $F"
	if [ "$3" != "dryrun" ]
	then
	    sed -i -e "s/#include \"$ESCAPEDOLDTRUNCPATH\"/#include \"$ESCAPEDNEWTRUNCPATH\"/" $F
	fi
    done
done
