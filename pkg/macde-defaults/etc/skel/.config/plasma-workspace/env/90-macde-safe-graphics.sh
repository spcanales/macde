#!/bin/sh

# Prefer software rendering in live/old GPU scenarios to avoid black screen + cursor.
export QT_QUICK_BACKEND=software
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
export LIBGL_ALWAYS_SOFTWARE=1
export KWIN_COMPOSE=Q
