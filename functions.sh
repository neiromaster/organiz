#!/bin/bash

# Function to check if required commands are available
function check_commands() {
  local required_commands="date rclone sed rg awk curl cmp mktemp head rev cut"
  local command
  local missing_commands=""
  for command in $required_commands; do
    if ! command -v "$command" &>/dev/null; then
      missing_commands+="$command "
    fi
  done
  if [ -n "$missing_commands" ]; then
    log_error_and_exit "Required commands not found: $missing_commands"
  fi
}

# Function to format date and time
function format_date() {
  date +"%Y/%m/%d-%H:%M:%S"
}

# Function to log messages with timestamp
function log_message() {
  echo "$(format_date) - $1" >>"$LOG_FILE"
}

function log_error() {
  echo "$(format_date) - ERROR: $1" >>"$LOG_FILE"
}

function log_rclone() {
  echo "$1" >>"$LOG_FILE"
}

# Function to log errors and exit
function log_error_and_exit() {
  log_error "$1"
  exit 1
}

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
  raw_name=$(echo "$name" | rg -oP '^.*?(?=( - | \[))')
  name=$(trim_all "$raw_name")
  echo -n "$name"
}

# function to get anime season
# $1 - file name
function get_anime_season() {
  local name="$*"
  local rawSeason
  rawSeason=$(echo "$name" | rg -oP '(?<=\[).*?(?=\])' | head -n 1)
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
  name=$(echo "$name" | rg -oP '(?<=\s-\s)\d+')
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
  local OLDIFS
  local file_list
  local error_output

  if [ -z "$source_path" ]; then
    log_message "source_path is empty. Exit"
    return
  fi

  if [ -z "$store_path" ]; then
    log_message "store_path is empty. Exit"
    return
  fi

  error_output=$(rclone mkdir "$source_path" 2>&1 >/dev/null)
  if [ $? -ne 0 ]; then
    log_error "Failed to create source directory: $source_path"
    log_rclone "$error_output"
  fi
  error_output=$(rclone mkdir "$store_path" 2>&1 >/dev/null)
  if [ $? -ne 0 ]; then
    log_error "Failed to create store directory: $store_path"
    log_rclone "$error_output"
  fi

  # traverse all top-level files in a source folder
  OLDIFS=$IFS
  file_list=$(rclone lsf -R --files-only "$source_path")
  IFS=$'\n'
  for file in $file_list; do
    filename=$(basename "$file")
    # skip files that do not start with file_filter in any case
    if ! echo "$filename" | rg -iq "$file_filter"; then
      continue
    fi

    anime_ext=$(echo "$filename" | rev | cut -d '.' -f 1 | rev)

    # if the file extension is longer than 3 characters, skip iteration
    if [ ${#anime_ext} -gt 3 ]; then
      log_message "Skip an incomplete file: $filename"
      continue
    fi

    name=$(clear_file_name "$filename")

    anime_name=$(get_anime_name "$name")
    anime_season=$(get_anime_season "$name")
    anime_episode=$(get_anime_episode "$name")

    dirname=$(find_similar "$anime_name" "$source_path")

    error_output=$(rclone mkdir "$store_path/$dirname" 2>&1 >/dev/null)
    if [ $? -ne 0 ]; then
      log_error "Failed to create directory: $store_path/$dirname"
      log_rclone "$error_output"
      continue
    fi

    error_output=$(rclone moveto "$source_path/$file" "$store_path/$dirname/$anime_season$anime_episode$anime_name.$anime_ext" 2>&1 >/dev/null)
    if [ $? -ne 0 ]; then
      log_error "Failed to move file: $file to $dirname/$anime_season$anime_episode$anime_name.$anime_ext"
      log_rclone "$error_output"
      continue
    fi
    log_message "Move file to store: $file to $dirname/$anime_season$anime_episode$anime_name.$anime_ext"
  done
  IFS=$OLDIFS
}

function sync_store_and_backup() {
  local store_path="$1"
  local backup_path="$2"
  local rclone_output

  if [ -n "$backup_path" ]; then
    log_message "Syncing store and backup: $store_path <-> $backup_path"
    rclone_output=$(rclone bisync "$store_path" "$backup_path" 2>&1)
    if [ $? -ne 0 ]; then
      log_error "Failed to sync store and backup: $store_path <-> $backup_path"
    fi
    log_rclone "$rclone_output"
  fi
}

function filling {
  local store_path="$1"
  local destination_path="$2"
  local target_size="$3"
  local max_files="$4"
  local total_size
  local newdir
  local count
  local newcount
  local directory
  local directories
  local file
  local files_to_move
  local file_list
  local error_output

  # if store_path is empty, then finish the job
  if [ -z "$store_path" ]; then
    log_message "store_path is empty. Exit"
    return
  fi

  # if destination_path is empty, then finish the job
  if [ -z "$destination_path" ]; then
    log_message "destination_path is empty. Exit"
    return
  fi

  if [ -z "$max_files" ]; then
    log_message "max_files is empty. Exit"
    return
  fi

  log_message "Second step: Move files to $destination_path"

  error_output=$(rclone mkdir "$destination_path" 2>&1 >/dev/null)
  if [ $? -ne 0 ]; then
    log_error "Failed to create destination directory: $destination_path"
    log_rclone "$error_output"
  fi

  OLDIFS=$IFS
  directories=$(rclone lsf --dirs-only -d=false "$store_path")
  IFS=$'\n'
  # traverse all store_path subfolders
  for directory in $directories; do
    total_size=$(rclone size "$destination_path" --json | grep -o '"bytes":[0-9]*' | grep -o '[0-9]*')
    # if total_size is greater than 20G, then terminate the script
    if [ "$total_size" -gt "$target_size" ]; then
      log_message "Total size: $total_size. Exit"
      return
    fi

    newdir="$destination_path/$(basename "$directory")"
    # if there is no folder named newdir, create one
    error_output=$(rclone mkdir "$newdir" 2>&1 >/dev/null)
    if [ $? -ne 0 ]; then
      log_error "Failed to create directory: $newdir"
      log_rclone "$error_output"
      continue
    fi

    count=$(rclone lsf --files-only --exclude '.*' "$newdir" | wc -l)
    log_message "$count files in $newdir"

    if [ "$count" -lt "$max_files" ]; then
      # move no more than two files from the directory to the new folder

      file_list=$(rclone lsf --files-only -R --exclude '.*' "$store_path/$directory" | awk -F/ '{key="";for(i=1;i<=NF;i++){p="1";if(i==NF)p="0";key=key (key==""?"":OFS) p$i}print key"\t"$0}' OFS=' / ' | sort -t"$(printf '\t')" -k1,1f | cut -d"$(printf '\t')" -f2)

      # calculate the number of files to be migrated: the redistributed number minus the number in count
      newcount=$((max_files - count))

      files_to_move=$(echo "$file_list" | head -"$newcount")

      for file in $files_to_move; do
        error_output=$(rclone move "$store_path/$directory/$file" "$newdir" 2>&1 >/dev/null)
        if [ $? -ne 0 ]; then
          log_error "Failed to move file: $file from $store_path/$directory to $newdir"
          log_rclone "$error_output"
          continue
        fi
      done

      log_message "Move files to target folder: $newcount files from $directory to $newdir"
    fi

    # delete an empty folder
    if [ -z "$(rclone lsf --files-only -R --exclude '.*' "$store_path/$directory")" ]; then
      error_output=$(rclone rmdirs "$store_path/$directory" 2>&1 >/dev/null)
      if [ $? -ne 0 ]; then
        log_error "Failed to remove empty store folder: $store_path/$directory"
        log_rclone "$error_output"
        continue
      fi
      log_message "Remove empty store folder: $directory"
    fi
  done
  IFS=$OLDIFS
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

# Function to update the script
function update_script() {
  # Get the download link for the latest version of the script from GitHub
  local script_url
  script_url=$(curl -s https://api.github.com/repos/neiromaster/organiz/releases/latest | awk -F'"' '/browser_download_url/ {print $4}')

  local release_number
  release_number=$(echo "$script_url" | awk -F'/' '{print $(NF-1)}')

  # Create a temporary file
  local temp_script
  temp_script=$(mktemp)

  log_message "Downloading the latest release of the script"
  if curl -s -L -o "$temp_script" "$script_url"; then
    log_message "Latest release of the script downloaded."
  else
    log_error "Failed to download the release. Exit"
    rm "$temp_script"
    exit 1
  fi

  # Check if the files are different
  if cmp -s "$0" "$temp_script"; then
    log_message "The script is already up-to-date."
  else
    # Copy the new version over the current one
    cp "$temp_script" "$0"

    # Set execution permissions on the script
    chmod +x "$0"

    log_message "The script has been updated. Release number: $release_number"

    # Remove the temporary file
    rm "$temp_script"

    # Restart the script
    exec $0 "$@"

    exit
  fi

  # Remove the temporary file
  rm "$temp_script"
}
