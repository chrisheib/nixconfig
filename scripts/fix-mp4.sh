#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  exit 1
fi

for input in "$@"; do
  if [ ! -f "$input" ]; then
    continue
  fi

  dir="$(dirname "$input")"
  name="$(basename "$input")"
  base="${name%.*}"
  ext="${name##*.}"

  renamed="$dir/_$name"
  output="$dir/${base}_fixed.mp4"

  if [ -e "$renamed" ]; then
    echo "Skipping '$input': '$renamed' already exists." >&2
    continue
  fi

  if [ -e "$output" ]; then
    echo "Skipping '$input': '$output' already exists." >&2
    continue
  fi

  mv -- "$input" "$renamed"

  if ffmpeg -i "$renamed" -c:v copy -c:a aac -b:a 192k "$name"; then
    rm -- "$renamed"
    echo "Converted: '$input' -> '$name'"
  else
    echo "Conversion failed for '$renamed'. Source kept as '$renamed'." >&2
  fi
done