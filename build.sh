#!/bin/bash

mkdir -p build
cmake -DCMAKE_INSTALL_PREFIX=/tools -DCMAKE_TOOLCHAIN_FILE=$PWD/targets/aarch64.cmake -S heaptrack -B build
