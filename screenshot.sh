#!/bin/sh
# export QT_QPA_PLATFORM=xcb

# output="$(flameshot full --path "$HOME/Pictures/Screenshots" 2>&1)"
# printf '%s\n' "$output"

# # Extract the final saved file path from flameshot output.
# image_path="$(printf '%s\n' "$output" | sed -n 's/^.*Capture saved as \(.*\)$/\1/p' | tail -n 1)"

# if [ -n "$image_path" ] && [ -f "$image_path" ]; then
# 	pinta "$image_path" >/dev/null 2>&1 &
# else
# 	printf '%s\n' 'Could not determine screenshot path from flameshot output.' >&2
# 	exit 1
# fi

# spectacle --background --region --copy-image --nonotify
spectacle --background --region --nonotify --output /tmp/screen.png && wl-copy < /tmp/screen.png
