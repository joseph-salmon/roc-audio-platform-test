#!/bin/bash

# Clean up any existing object files
rm -f platform/macos-arm64.o

# Build main.roc
ROC_LINK_FLAGS="-lportaudio" roc dev app.roc || exit 1

# Clean up object files after execution
rm -f platform/macos-arm64.o

exit 0

