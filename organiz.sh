#!/usr/bin/env bash

source functions.sh

# If the file config.sh if it does not exist, then copy it from config.example.sh
if [ ! -f config ]; then
    cp config.example config
    echo "config created. Please edit it and restart the script"
    exit 0
fi

source config

echo -e "Start: source $sourcePath\ndestination $storePath"

# if sourcePath is empty, then finish the job
if [ -z "$sourcePath" ]; then
    echo "sourcePath is empty. Exit"
    exit 0
fi

mkdir -p "$sourcePath"
mkdir -p "$storePath"

# traverse all top-level files in a source folder
shopt -s globstar nullglob
for file in "$sourcePath"/**/*; do
    # if it's a directory, skip
    if [ -d "$file" ]; then
        continue
    fi

    filename=$(basename "$file")
    # skip files that do not start with fileFilter in any case
    if ! echo "$filename" | grep -iq "$fileFilter"; then
        continue
    fi

    animeExt=$(echo "$filename" | rev | cut -d '.' -f 1 | rev)

    # if the file extension is longer than 3 characters, skip iteration
    if [ ${#animeExt} -gt 3 ]; then
        echo "Skip an incomplete file: $filename"
        continue
    fi

    name=$(clearFileName "$filename")

    animeName=$(getAnimeName "$name")
    animeSeason=$(getAnimeSeason "$name")
    animeEpisode=$(getAnimeEpisode "$name")

    dirname=$(findSimilar "$animeName" "$sourcePath")

    mkdir -p "$storePath/$dirname"

    mv "$file" "$storePath/$dirname/$animeSeason$animeEpisode$animeName.$animeExt"
    echo "Move file to store: $file to $dirname/$animeSeason$animeEpisode$animeName.$animeExt"
done

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

    if [ "$count" -lt 2 ]; then
        # move no more than two files from the directory to the new folder
        cd "$directory" || exit

        # calculate the number of files to be migrated: the redistributed number minus the number in count
        newcount=$((2 - count))

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
