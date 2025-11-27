#!/usr/bin/env bash

if [ -z "$DEVKITPRO" ]; then
    echo "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitpro"
    exit 1
fi

getBuildPath() {
    echo "build/"
}

# args
CLEAN=0
VERBOSE=0
RELEASE=0
TARGET=""
SEND=0
WARNINGS=0
ALLWARNINGS=0
EXTRAWARNINGS=0

while [ $# -gt 0 ]; do
    case "$1" in
        -c) CLEAN=1 ;;  # Clean before building
        -v) VERBOSE=1 ;;  # Give verbose output
        -r) RELEASE=1 ;;  # Optimize for release build (Default: Debug)
        -t) TARGET="$2"; shift ;;  # Specify custom target
        -s) SEND=1 ;;   # Send file after building (overrides -t)
        -w) WARNINGS=1 ;;   # Do not hide warnings (Ok)
        -a) ALLWARNINGS=1 ;;  # Show all warnings ( Abfahrt. )
        -u) EXTRAWARNINGS=1 ;;  # Show every warning possible for gcc (  Eskalationsstufe 9: Gemeinsamer Untergang.  )
    esac
    shift
done

# Prepare Build
BUILD_DIR="$(getBuildPath)"

if [ "$CLEAN" -eq 1 ]; then
    rm -rf "$BUILD_DIR"
fi

if [ -f "${BUILD_DIR}CMakeCache.txt" ]; then
    rm -f "${BUILD_DIR}CMakeCache.txt"
fi

# Configure
cmake_args=(
    cmake
    -S .
    -B "$BUILD_DIR"
    -G "Unix Makefiles"
    "-DCMAKE_TOOLCHAIN_FILE=$DEVKITPRO/cmake/3DS.cmake"
)

if [ "$RELEASE" -eq 1 ]; then
    cmake_args+=("-DCMAKE_BUILD_TYPE=Release")
else
    cmake_args+=("-DCMAKE_BUILD_TYPE=Debug")
fi

[ "$EXTRAWARNINGS" -eq 1 ] && cmake_args+=("-DEXTRAWARNINGS=1")
[ "$ALLWARNINGS" -eq 1 ]   && cmake_args+=("-DALLWARNINGS=1")
[ "$WARNINGS" -eq 1 ]      && cmake_args+=("-DWARNINGS=1")

"${cmake_args[@]}" || exit 1

# Build
make_args=( cmake --build "$BUILD_DIR" )

if [ -n "$TARGET" ]; then
    make_args+=("-t $TARGET")
fi

[ "$VERBOSE" -eq 1 ] && make_args+=("--verbose")

"${make_args[@]}" || exit 1

if [ "$SEND" -eq 1 ]; then
    cmake --build "$BUILD_DIR" -t send
fi

