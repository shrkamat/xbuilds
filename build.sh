#!/bin/bash
mkdir -p build
cmake -DCMAKE_TOOLCHAIN_FILE=$PWD/targets/aarch64.cmake -S lttng -B build
