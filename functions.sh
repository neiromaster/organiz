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
function trim_all() {
    local var="$*"
    var="$(echo -e "${var}" | sed -e 's/^[[:space:]-]*//' -e 's/[[:space:]-]*$//')"
    echo -n "$var"
}

# function to remove begin text in square brackets and extension
# $1 - string
function clear_file_name() {
    local var="$*"
    var="$(echo -e "${var}" | sed -e 's/^\[[^]]*\]//')"
    var="$(echo -e "${var}" | sed -e 's/\.[^.]*$//')"
    var=$(trim_all "$var")
    echo -n "$var"
}

# function to get anime name
# $1 - file name
function get_anime_name() {
    local name="$*"
    local raw_name
    raw_name=$(echo "$name" | grep -oP '^.*?(?=( - | \[))')
    name=$(trim_all "$raw_name")
    echo -n "$name"
}

# function to get anime season
# $1 - file name
function get_anime_season() {
    local name="$*"
    local rawSeason
    rawSeason=$(echo "$name" | grep -oP '(?<=\[).*?(?=\])' | head -n 1)
    name=$(trim_all "$rawSeason")
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
function get_anime_episode() {
    local name="$*"
    name=$(echo "$name" | grep -oP '(?<=\s-\s)\d+')
    name=$(trim_all "$name")

    # If $anime_episode is not empty, add a space at the end of it
    if [ -n "$name" ]; then
        name="$name "
    fi
    echo -n "$name"
}

# function to find similar directories
# $1 - anime name
# $2 - path
function find_similar() {
    local name="$1"
    local path="$2"
    local directory
    local dirname

    for directory in "$path"/*; do
        if [ ! -d "$directory" ]; then
            continue
        fi

        dirname=$(basename "$directory")
        # if the levenstein distance between directory and anime_name is less than 3, then exit the loop.
        if [[ $(levenshtein "$dirname" "$name") -lt 3 ]]; then
            echo -n "$dirname"
            return
        fi
    done

    echo -n "$name"
}

function aniparse() {
    local source_path="$1"
    local store_path="$2"
    local file_filter="$3"
    local file
    local filename
    local anime_ext
    local anime_name
    local anime_season
    local anime_episode
    local dirname

    if [ -z "$source_path" ]; then
        echo "source_path is empty. Exit"
        return
    fi

    if [ -z "$store_path" ]; then
        echo "store_path is empty. Exit"
        return
    fi

    mkdir -p "$source_path"
    mkdir -p "$store_path"

    # traverse all top-level files in a source folder
    shopt -s globstar nullglob
    for file in "$source_path"/**/*; do
        # if it's a directory, skip
        if [ -d "$file" ]; then
            continue
        fi

        filename=$(basename "$file")
        # skip files that do not start with file_filter in any case
        if ! echo "$filename" | grep -iq "$file_filter"; then
            continue
        fi

        anime_ext=$(echo "$filename" | rev | cut -d '.' -f 1 | rev)

        # if the file extension is longer than 3 characters, skip iteration
        if [ ${#anime_ext} -gt 3 ]; then
            echo "Skip an incomplete file: $filename"
            continue
        fi

        name=$(clear_file_name "$filename")

        anime_name=$(get_anime_name "$name")
        anime_season=$(get_anime_season "$name")
        anime_episode=$(get_anime_episode "$name")

        dirname=$(find_similar "$anime_name" "$source_path")

        mkdir -p "$store_path/$dirname"

        mv "$file" "$store_path/$dirname/$anime_season$anime_episode$anime_name.$anime_ext"
        echo "Move file to store: $file to $dirname/$anime_season$anime_episode$anime_name.$anime_ext"
    done
}

function filling {
    local store_path="$1"
    local destination_path="$2"
    local target_size="$3" || 1000000000 # 1TB
    local max_files="$4"
    local total_size
    local newdir
    local count
    local newcount
    local directory

    # if store_path is empty, then finish the job
    if [ -z "$store_path" ]; then
        echo "store_path is empty. Exit"
        exit 0
    fi

    # if destination_path is empty, then finish the job
    if [ -z "$destination_path" ]; then
        echo "destination_path is empty. Exit"
        exit 0
    fi

    if [ -z "$max_files" ]; then
        echo "max_files is empty. Exit"
        exit 0
    fi

    echo -e "Second step:\nMove files to $destination_path"

    mkdir -p "$destination_path"

    # traverse all store_path subfolders
    for directory in "$store_path"/*; do
        if [ ! -d "$directory" ]; then
            continue
        fi

        total_size=$(du -s "$destination_path" | cut -f 1)
        # if total_size is greater than 20G, then terminate the script
        if [ "$total_size" -gt "$target_size" ]; then
            echo "Total size: $total_size. Exit"
            exit 0
        fi

        newdir="$destination_path/$(basename "$directory")"
        # if there is no folder named newdir, create one
        mkdir -p "$newdir"

        count=$(ls -1 "$newdir" | wc -l)
        echo "$count files in $newdir"

        if [ "$count" -lt "$max_files" ]; then
            # move no more than two files from the directory to the new folder
            cd "$directory" || exit

            # calculate the number of files to be migrated: the redistributed number minus the number in count
            newcount=$((max_files - count))

            ls -1 | sort | head -"$newcount" | xargs -I {} mv {} "$newdir"
            echo "Move files to target folder: $newcount files from $directory to $newdir"
        fi

        # delete an empty folder
        if [ -z "$(ls -A "$directory")" ]; then
            rm -rf "$directory"
            echo "Remove empty store folder: $directory"
        fi
    done
}

function parse_ini() {
    local ini_file="$1"
    local section="$2"
    local property="$3"
    local value
    value=$(awk -F '=' -v section="$section" -v property="$property" '
        /^\[.*\]$/ {
            in_section = 0
        }
        $0 ~ "^\\[" section "\\]$" {
            in_section = 1
        }
        in_section && $1 == property {
            print $2
            exit
        }
    ' "$ini_file")

    echo "$value"
}

# This function extracts the sections from the specified INI file and prints them to the standard output.
function get_ini_sections() {
    local ini_file="$1"
    awk -F '[][]' '/\[.*\]/{print $2}' "$ini_file"
}
