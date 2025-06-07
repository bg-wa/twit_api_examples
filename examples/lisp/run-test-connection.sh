#!/bin/bash

# Run the TWiT API client test connection
# This script ensures the proper environment is set up

# Set paths
LISP_DIR="$HOME/.local/share/twit-lisp"
SBCL_BIN="$LISP_DIR/bin/sbcl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we have a script to run
if [ -z "$1" ]; then
  echo "Usage: $0 <lisp-script>"
  exit 1
fi

SCRIPT_PATH="$SCRIPT_DIR/$1"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: Script $SCRIPT_PATH not found"
  exit 1
fi

# Run with local SBCL if available, otherwise use system SBCL
if [ -x "$SBCL_BIN" ]; then
  echo "Using local SBCL installation"
  "$SBCL_BIN" --noinform --load "$SCRIPT_PATH"
else
  echo "Using system SBCL"
  sbcl --noinform --load "$SCRIPT_PATH"
fi
