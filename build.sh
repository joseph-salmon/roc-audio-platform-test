#!/bin/bash

# Clean up any existing object files
rm -f main.o host.o

# Compile host.c
gcc -c platform/host.c || exit 1

# Build main.roc
roc build --no-link --emit-llvm-ir app.roc || exit 1

# Link and compile main with host.o and portaudio library
gcc -o app app.o host.o -lportaudio || exit 1

# Run the program
./app

# Clean up object files after execution
rm -f app.o host.o

exit 0

