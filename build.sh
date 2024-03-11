#!/usr/bin/env bash

# A function for processing the source directive
process_include() {
    local file="$1"

    while IFS= read -r line; do
        if [[ "$line" =~ ^\source\ (.+) ]]; then
            process_include "${BASH_REMATCH[1]}"
        else
            echo "$line"
        fi
    done <"$file"
}

# If the file config.sh if it does not exist, then copy it from config.example.sh
if [ ! -f config ]; then
    cp config.example config
    echo "config created. Please edit it and restart the script"
    exit 0
fi

# Starting file processing
process_include organiz.sh | sed -e '2,$ s/^#!.*//' -e '/^$/ d' > build/organiz.sh

