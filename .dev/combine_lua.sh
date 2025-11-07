#!/bin/bash
cat src/0_label.txt
echo

find src -type f -name "*.lua" | sort | while read -r file; do
  echo "-- $file"
  cat "$file"
  echo
done
