#!/bin/bash

find src -type f -name "*.lua" | sort | while read -r file; do
  echo "-- $file"
  cat "$file"
  echo
done
