#!/usr/bin/env bash

source functions.sh

source config

echo -e "Start: source $sourcePath\ndestination $storePath"

# если sourcePath задано, то запускаем функцию aniparse
aniparse "$sourcePath" "$storePath" "$fileFilter"

# if destinationPath is empty, then finish the job
if [ -z "$destinationPath" ]; then
    echo "destinationPath is empty. Exit"
    exit 0
fi

echo -e "Second step:\nMove files to $destinationPath"

mkdir -p "$destinationPath"

# traverse all storePath subfolders
for directory in "$storePath"/*; do
    if [ ! -d "$directory" ]; then
        continue
    fi

    totalSize=$(du -s "$destinationPath" | cut -f 1)
    # if totalSize is greater than 20G, then terminate the script
    if [ "$totalSize" -gt "$targetSize" ]; then
        echo "Total size: $totalSize. Exit"
        exit 0
    fi

    newdir="$destinationPath/$(basename "$directory")"
    # if there is no folder named newdir, create one
    mkdir -p "$newdir"

    count=$(ls -1 "$newdir" | wc -l)
    echo "$count files in $newdir"

    if [ "$count" -lt $maxFiles ]; then
        # move no more than two files from the directory to the new folder
        cd "$directory" || exit

        # calculate the number of files to be migrated: the redistributed number minus the number in count
        newcount=$((maxFiles - count))


        ls -1 | sort | head -"$newcount" | xargs -I {} mv {} "$newdir"
        echo "Move files to target folder: $newcount files from $directory to $newdir"
    fi

    # delete an empty folder
    if [ -z "$(ls -A "$directory")" ]; then
        rm -rf "$directory"
        echo "Remove empty store folder: $directory"
    fi
done

echo "Done"
echo "Total size: $(du -s "$destinationPath" | cut -f 1)"
