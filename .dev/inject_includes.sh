#!/bin/bash

SRC_DIR="src"
P8_FILE="cartridge.p8"
TMP_FILE="$P8_FILE.tmp"

INCLUDES=$(find "$SRC_DIR" -name "*.lua" | sort | sed 's/^/#include /')

# Replace __lua__ section with #include lines
awk -v includes="$INCLUDES" '
BEGIN { in_lua=0 }
/^__lua__$/ {
  print "__lua__"
  print includes
  in_lua=1
  next
}
/^__.*__$/ {
  in_lua=0
}
!in_lua { print }
' "$P8_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$P8_FILE"
