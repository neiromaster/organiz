#!/usr/bin/env bash

source functions.sh

config_file=
if [ -f config.conf ]; then
    config_file=$(realpath config.conf)
elif [ -f "${HOME}/.config.conf" ]; then
    config_file=$(realpath "${HOME}/.config.conf")
elif [ -f "${XDG_CONFIG_HOME:-${HOME}/.config}/organiz/config.conf" ]; then
    config_file=$(realpath "${XDG_CONFIG_HOME:-${HOME}/.config}/organiz/config.conf")
else
    echo "Config file not found"
    exit 1
fi

section=$(get_ini_sections "$config_file")

if [ -z "$section" ]; then
    echo "No sections found"
    exit 1
fi

for section in $section; do
    source_path=$(parse_ini "$config_file" "$section" source_path)
    store_path=$(parse_ini "$config_file" "$section" store_path)
    destination_path=$(parse_ini "$config_file" "$section" destination_path)
    file_filter=$(parse_ini "$config_file" "$section" file_filter)
    target_size=$(parse_ini "$config_file" "$section" target_size)
    max_files=$(parse_ini "$config_file" "$section" max_files)

    echo "Section: $section"
    echo "Source: $source_path"
    echo "Store: $store_path"
    echo "Destination: $destination_path"
    echo "File filter: $file_filter"
    echo "Target size: $target_size"
    echo "Max files: $max_files"
    echo ""

    echo -e "Start: source $source_path\nsource $store_path"

    aniparse "$source_path" "$store_path" "$file_filter"

    filling "$store_path" "$destination_path" "$target_size" "$max_files"

    echo "Done section $section"
    echo ""
    
    if [ -z "$destination_path" ]; then
        continue
    fi
    
    echo "Total size: $(du -s "$destination_path" | cut -f 1)"
    echo ""
done
