#!/bin/bash
export MOZ_ENABLE_WAYLAND=1        # Use Wayland if available; omit if you're sticking to X11.
# export MOZ_X11_EGL=1               # Only if on X11, and you want to force EGL-based rendering.
export LIBVA_DRIVER_NAME=radeonsi    # Explicitly point Firefox to the AMD VA-API driver.
exec firefox "$@"
