#!/bin/bash

# This script verifies the final "Files-First" sorting logic.

read -r -d '' ORIGINAL_LIST <<'EOF'
LTspice/examples/examples.json
qqqq/domains.txt
Obsidian Vault/Шаблон пылесоса.md
Zettlr Tutorial/LaTeX Guide.pdf
Obsidian Vault/_attachments/Pasted image 20240216185229.png
Obsidian Vault/_attachments/Pasted image 20230627130353.png
Zettlr Tutorial/welcome.md
Obsidian Vault/_attachments/SCR-20230627-p7k.png
Zettlr Tutorial/LaTeX Guide.md
qqqq/init__
qqqq/check-domains
qqqq/copilot_microsoft_com_domains.txt
Shutter Encoder/settings.xml
Zettlr Tutorial/citing.md
Zettlr Tutorial/helpful-links.md
LTspice/examples/stamp.bin
Zettlr Tutorial/references.json
Zettlr Tutorial/split-view-intro.md
Zettlr Tutorial/zettelkasten.md
Zettlr Tutorial/zettlr.png
qqqq/ya_ru_domains.txt
EOF

read -r -d '' RESULT_LIST <<'EOF'
LTspice/examples/examples.json
LTspice/examples/stamp.bin
Obsidian Vault/Шаблон пылесоса.md
Obsidian Vault/_attachments/Pasted image 20230627130353.png
Obsidian Vault/_attachments/Pasted image 20240216185229.png
Obsidian Vault/_attachments/SCR-20230627-p7k.png
qqqq/init__
qqqq/domains.txt
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

# The "Files-First" sorting command.
ACTUAL_LIST=$(echo "$ORIGINAL_LIST" | awk -F/ '{key="";for(i=1;i<=NF;i++){p="1";if(i==NF)p="0";key=key (key==""?"":OFS) p$i}print key"\t"$0}' OFS=' / ' | sort -t"$(printf '\t')" -k1,1f | cut -d"$(printf '\t')" -f2)


# Compare the actual output with the correct output
diff_output=$(diff <(echo "$RESULT_LIST") <(echo "$ACTUAL_LIST"))

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
