#!/bin/bash

# This script verifies the final sorting logic.
# It takes a list of unsorted files, applies the sorting command,
# and compares the result with the known correct output using diff.
# The script will exit with status 0 only if the output is a perfect match.

# The unsorted list, as provided by the user in a previous message.
read -r -d '' UNSORTED_LIST <<'EOF'
Obsidian Vault/Шаблон пылесоса.md
qqqq/__init__
qqqq/_domains.txt
qqqq/check-domains
qqqq/copilot_microsoft_com_domains.txt
qqqq/ya_ru_domains.txt
Shutter Encoder/settings.xml
Zettlr Tutorial/citing.md
Zettlr Tutorial/helpful-links.md
Zettlr Tutorial/LaTeX Guide.md
Zettlr Tutorial/LaTeX Guide.pdf
Zettlr Tutorial/references.json
Zettlr Tutorial/split-view-intro.md
Zettlr Tutorial/welcome.md
Zettlr Tutorial/zettelkasten.md
Zettlr Tutorial/zettlr.png
LTspice/examples/examples.json
LTspice/examples/stamp.bin
Obsidian Vault/_attachments/Pasted image 20230627130353.png
Obsidian Vault/_attachments/Pasted image 20240216185229.png
Obsidian Vault/_attachments/SCR-20230627-p7k.png
Obsidian Vault/.git/COMMIT_EDITMSG
EOF

# The final, correct sorted list, updated with the user's latest correction.
read -r -d '' CORRECT_LIST <<'EOF'
LTspice/examples/examples.json
LTspice/examples/stamp.bin
Obsidian Vault/Шаблон пылесоса.md
Obsidian Vault/_attachments/Pasted image 20230627130353.png
Obsidian Vault/_attachments/Pasted image 20240216185229.png
Obsidian Vault/_attachments/SCR-20230627-p7k.png
Obsidian Vault/.git/COMMIT_EDITMSG
qqqq/__init__
qqqq/_domains.txt
qqqq/check-domains
qqqq/copilot_microsoft_com_domains.txt
qqqq/ya_ru_domains.txt
Shutter Encoder/settings.xml
Zettlr Tutorial/citing.md
Zettlr Tutorial/helpful-links.md
Zettlr Tutorial/LaTeX Guide.md
Zettlr Tutorial/LaTeX Guide.pdf
Zettlr Tutorial/references.json
Zettlr Tutorial/split-view-intro.md
Zettlr Tutorial/welcome.md
Zettlr Tutorial/zettelkasten.md
Zettlr Tutorial/zettlr.png
EOF

# The final, corrected sorting command. Added -d flag for dictionary sort.
ACTUAL_LIST=$(echo "$UNSORTED_LIST" | awk '{depth=gsub(/\//,"/");if(depth==0){printf "0\t%s\t0\t0\t%s\n",$0,$0;}else{group=$0;sub(/\/.*/,"",group);is_dot=0;path_after=substr($0,length(group)+2);if(substr(path_after,1,1)=="."){is_dot=1;}printf "1\t%s\t%d\t%d\t%s\n",group,depth,is_dot,$0;}}' | LC_ALL=C sort -t"$(printf '\t')" -k1,1n -k2,2f -k3,3n -k4,4n -k5,5df | cut -d"$(printf '\t')" -f5)

# Compare the actual output with the correct output
diff_output=$(diff <(echo "$CORRECT_LIST") <(echo "$ACTUAL_LIST"))

if [ -z "$diff_output" ]; then
  echo "SUCCESS: The sorted output perfectly matches the expected output."
  exit 0
else
  echo "FAILURE: The sorted output does not match the expected output."
  echo "--- DIFF ---"
  echo "$diff_output"
  echo "--------------"
  exit 1
fi
