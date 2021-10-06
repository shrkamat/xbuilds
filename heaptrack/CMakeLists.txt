cmake_minimum_required(VERSION 3.10.2)

project (heaptrack)

include (ExternalProject)

# output directory
# source directory
set (SRC_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/staging)
set (SRC_DL ${CMAKE_CURRENT_SOURCE_DIR}/dl)
set (SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/staging)

MESSAGE("prefix: " ${CMAKE_INSTALL_PREFIX})

ExternalProject_Add (
    libz
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    URL                     https://zlib.net/zlib-1.2.11.tar.gz
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       CHOST=${XHOST} ./configure --prefix=${CMAKE_INSTALL_PREFIX}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    bzip2
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://sourceware.org/git/bzip2.git
    GIT_TAG                 bzip2-1.0.8
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ""
    BUILD_COMMAND           make CC=${XHOST}-gcc CXX=${XHOST}-g++ PREFIX=/tools install
    INSTALL_COMMAND         ""
)

ExternalProject_Add(
    boost
    DEPENDS                 libz bzip2
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://github.com/boostorg/boost.git
    GIT_TAG                 "boost-1.77.0"
# hackish implementation, sed should run only once
    PATCH_COMMAND           
        COMMAND             ./bootstrap.sh --with-libraries=filesystem,iostreams,program_options --prefix=/tools
        COMMAND             sed -i "s|using gcc|using gcc : arm : aarch64-linux-gnu-g++|g" project-config.jam
    CONFIGURE_COMMAND       ""
    BUILD_COMMAND           ./b2
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND         ./b2 install
)


# ExternalProject_Add (
#     libunwind
#     PREFIX                  ${SRC_PREFIX}
#     DOWNLOAD_DIR            ${SRC_DL}
#     GIT_REPOSITORY          https://github.com/libunwind/libunwind.git
#     CMAKE_ARGS
#                             -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
#                             -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
#                             -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
#                             -DCMAKE_CROSSCOMPILING=ON
# )

# ExternalProject_Add (
#     libdwarf
#     PREFIX                  ${SRC_PREFIX}
#     DOWNLOAD_DIR            ${SRC_DL}
#     URL                     https://www.prevanders.net/libdwarf-0.1.1.tar.xz
#     BUILD_IN_SOURCE         1
#     CONFIGURE_COMMAND       ./configure --prefix=${CMAKE_INSTALL_PREFIX} --host=${XHOST}
#     BUILD_COMMAND           make -j4
#     INSTALL_COMMAND         make install
# )

# Wierd problem zlib is not detected via pkg-config
# Learn zlib libs at run time (This approach wont work as zlib is not installed at cmake processing time)
# execute_process(COMMAND bash -c "PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig pkg-config --cflags zlib"  OUTPUT_VARIABLE elfutils_CFLAGS)
# execute_process(COMMAND bash -c "PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig pkg-config --libs-only-L zlib"  OUTPUT_VARIABLE elfutils_LDFLAGS)


# TODO: check how can this hardcode be removed 
SET(elfutils_LDFLAGS "-L${CMAKE_INSTALL_PREFIX}/lib")
SET(elfutils_CFLAGS "-I${CMAKE_INSTALL_PREFIX}/include")

MESSAGE("elfutils_LDFLAGS = " ${elfutils_LDFLAGS})
MESSAGE("elfutils_CFLAGS = " ${elfutils_CFLAGS})

ExternalProject_Add (
    elfutils
    DEPENDS                 libz
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    URL                     https://sourceware.org/elfutils/ftp/elfutils-latest.tar.bz2
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       PKG_CONFIG_PATH=${CMAKE_INSTALL_PREFIX}/lib/pkgconfig CFLAGS=${elfutils_CFLAGS} LDFLAGS=${elfutils_LDFLAGS} ./configure --prefix=${CMAKE_INSTALL_PREFIX} --host=${XHOST} --enable-libdebuginfod=dummy --disable-debuginfod
    BUILD_COMMAND           make -C libebl install && make -C backends install && make -C libcpu install && make -C libdwelf install && make -C libdwfl install && make -C lib install && make -C libelf install && make -C libdw install
    INSTALL_COMMAND         ""
)

ExternalProject_Add (
    heaptrack
    DEPENDS                 elfutils boost
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://github.com/KDE/heaptrack.git 
    GIT_TAG                 v1.2.0
    PATCH_COMMAND           patch -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/patches/heaptrack/0001-Fix-unable-to-disable-HEAPTRACK_BUILD_PRINT.patch
    CMAKE_ARGS
                            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                            -DCMAKE_CROSSCOMPILING=ON
                            -DCMAKE_C_FLAGS="-I${CMAKE_INSTALL_PREFIX}/include"
                            -DHEAPTRACK_BUILD_PRINT:BOOL=OFF
)
