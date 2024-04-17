#!/bin/bash

# Clean up any existing object files
rm -f main.o host.o

# Compile host.c
gcc -c platform/host.c || exit 1

# Build main.roc
roc build --no-link --emit-llvm-ir main.roc || exit 1

# Link and compile main with host.o and portaudio library
gcc -o main main.o host.o -lportaudio || exit 1

# Run the program
./main

# Clean up object files after execution
rm -f main.o host.o

exit 0

