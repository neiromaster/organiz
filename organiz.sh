#!/bin/bash

source functions.sh

update_script "$@"

config_file=
if [ -f config.conf ]; then
  config_file=$(realpath config.conf)
elif [ -f "${HOME}/.config.conf" ]; then
  config_file=$(realpath "${HOME}/.config.conf")
elif [ -f "${XDG_CONFIG_HOME:-${HOME}/.config}/organiz/config.conf" ]; then
  config_file=$(realpath "${XDG_CONFIG_HOME:-${HOME}/.config}/organiz/config.conf")
else
  log_error "Config file not found"
  exit 1
fi

section=$(get_ini_sections "$config_file")

if [ -z "$section" ]; then
  log_error "No sections found"
  exit 1
fi

for section in $section; do
  source_path=$(parse_ini "$config_file" "$section" source_path)
  store_path=$(parse_ini "$config_file" "$section" store_path)
  destination_path=$(parse_ini "$config_file" "$section" destination_path)
  file_filter=$(parse_ini "$config_file" "$section" file_filter)
  target_size=$(parse_ini "$config_file" "$section" target_size)
  max_files=$(parse_ini "$config_file" "$section" max_files)

  log_message "Section: $section"
  log_message "Source: $source_path"
  log_message "Store: $store_path"
  log_message "Destination: $destination_path"
  log_message "File filter: $file_filter"
  log_message "Target size: $target_size"
  log_message "Max files: $max_files"
  log_message ""

  log_message "Start: source $source_path, store $store_path"

  aniparse "$source_path" "$store_path" "$file_filter"

  filling "$store_path" "$destination_path" "$target_size" "$max_files"

  log_message "Done section $section"
  log_message ""

  if [ -z "$destination_path" ]; then
    continue
  fi

  log_message "Total size: $(rclone size "$destination_path" --json | grep -o '\"bytes\":[0-9]*' | grep -o '[0-9]*')"
  log_message ""
done
