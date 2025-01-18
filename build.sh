#!/usr/bin/env bash

# A function for processing the source directive
process_include() {
    local file="$1"
    local line

    while IFS= read -r line; do
        if [[ "$line" =~ ^\source\ (.+) ]]; then
            process_include "${BASH_REMATCH[1]}"
        else
            echo "$line"
        fi
    done <"$file"
}

mkdir -p build

# Starting file processing
process_include organiz.sh | sed -e '2,$ s/^#!.*//' -e '/^$/ d' > build/organiz.sh
