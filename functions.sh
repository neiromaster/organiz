#!/usr/bin/env bash

# function to calculate levenshtein distance
# $1 - target
# $2 - given
function levenshtein() {
    local -r -- target=$1
    local -r -- given=$2
    local -r -- targetLength=${#target}
    local -r -- givenLength=${#given}
    local -- alt
    local -- cost
    local -- ins
    local -- gIndex=0
    local -- lowest
    local -- nextGIndex
    local -- nextTIndex
    local -- tIndex
    local -A -- leven

    while (($gIndex <= $givenLength)); do

        tIndex=0
        while (($tIndex <= $targetLength)); do
            (($gIndex == 0)) && leven[0, $tIndex]=$tIndex
            (($tIndex == 0)) && leven[$gIndex, 0]=$gIndex

            ((tIndex++))
        done

        ((gIndex++))
    done

    gIndex=0
    while (($gIndex < $givenLength)); do

        tIndex=0
        while (($tIndex < $targetLength)); do
            [[ "${target:tIndex:1}" == "${given:gIndex:1}" ]] && cost=0 || cost=1

            ((nextTIndex = $tIndex + 1))
            ((nextGIndex = $gIndex + 1))

            ((del = leven[$gIndex, $nextTIndex] + 1))
            ((ins = leven[$nextGIndex, $tIndex] + 1))
            ((alt = leven[$gIndex, $tIndex] + $cost))

            ((lowest = $ins <= $del ? $ins : $del))
            ((lowest = $alt <= $lowest ? $alt : $lowest))
            leven[$nextGIndex, $nextTIndex]=$lowest

            ((tIndex++))
        done

        ((gIndex++))
    done

    echo -n $lowest
}

# function to trim leading and trailing whitespace characters
function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# function to trim leading and trailing whitespace characters with hyphens
# $1 - string
function trimAll() {
    local var="$*"
    var="$(echo -e "${var}" | sed -e 's/^[[:space:]-]*//' -e 's/[[:space:]-]*$//')"
    echo -n "$var"
}

# function to remove begin text in square brackets and extension
# $1 - string
function clearFileName() {
    local var="$*"
    var="$(echo -e "${var}" | sed -e 's/^\[[^]]*\]//')"
    var="$(echo -e "${var}" | sed -e 's/\.[^.]*$//')"
    var=$(trimAll "$var")
    echo -n "$var"
}

# function to get anime name
# $1 - file name
function getAnimeName() {
    local name="$*"
    local rawName
    rawName=$(echo "$name" | grep -oP '^.*?(?=( - | \[))')
    name=$(trimAll "$rawName")
    echo -n "$name"
}

# function to get anime season
# $1 - file name
function getAnimeSeason() {
    local name="$*"
    local rawSeason
    rawSeason=$(echo "$name" | grep -oP '(?<=\[).*?(?=\])' | head -n 1)
    name=$(trimAll "$rawSeason")
    # if there is no hyphen in $rawSeason, then reset the variable to empty, otherwise add a space to the end of the variable
    if [[ "$rawSeason" != *-* ]]; then
        name=""
    else
        name="$rawSeason "
    fi
    echo -n "$name"
}

# function to get anime episode
# $1 - file name
function getAnimeEpisode() {
    local name="$*"
    name=$(echo "$name" | grep -oP '(?<=\s-\s)\d+')
    name=$(trimAll "$name")

    # If $animeEpisode is not empty, add a space at the end of it
    if [ -n "$name" ]; then
        name="$name "
    fi
    echo -n "$name"
}

# function to find similar directories
# $1 - anime name
# $2 - path
function findSimilar() {
    local name="$1"
    local path="$2"
    local directory
    local dirname

    for directory in "$path"/*; do
        if [ ! -d "$directory" ]; then
            continue
        fi

        dirname=$(basename "$directory")
        # if the levenstein distance between directory and animeName is less than 3, then exit the loop.
        if [[ $(levenshtein "$dirname" "$name") -lt 3 ]]; then
            echo -n "$dirname"
            return
        fi
    done

    echo -n "$name"
}

function aniparse() {
    local sourcePath="$1"
    local storePath="$2"
    local fileFilter="$3"
    local file
    local filename
    local animeExt
    local animeName
    local animeSeason
    local animeEpisode
    local dirname

    if [ -z "$sourcePath" ] || [ -z "$storePath" ]; then
        echo "sourcePath or storePath is empty. Exit"
        return
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
}
