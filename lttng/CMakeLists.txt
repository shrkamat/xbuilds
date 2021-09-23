cmake_minimum_required(VERSION 3.10.2)

project (oss)

include (ExternalProject)

# output directory
set (OSS_PREFIX  /NDS)
# source directory
set (SRC_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/oss)
set (SRC_DL ${CMAKE_CURRENT_SOURCE_DIR}/dl)
set (SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/oss)
set (XHOST aarch64-linux-gnu)
set (XARGS "--host=${XHOST}")

ExternalProject_Add (
    libz
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    URL                     https://zlib.net/zlib-1.2.11.tar.gz
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       CHOST=${XHOST} ./configure --prefix=${OSS_PREFIX}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    libxml2
    DEPENDS                 libz
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://gitlab.gnome.org/GNOME/libxml2.git
    GIT_TAG                 v2.9.12
    DOWNLOAD_NO_PROGRESS    ON
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       PKG_CONFIG_PATH=${OSS_PREFIX}/lib/pkgconfig ./autogen.sh --prefix=${OSS_PREFIX} --without-python --disable-tests ${XARGS}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    urcu
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          git://git.liburcu.org/userspace-rcu.git
    GIT_TAG                 v0.13.0
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ./bootstrap && ./configure --disable-numa --disable-man-pages --disable-tests --disable-examples --prefix=${OSS_PREFIX} ${XARGS}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    lttng-ust
    DEPENDS                 urcu
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://github.com/lttng/lttng-ust.git
    GIT_TAG                 v2.13.0
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ./bootstrap && PKG_CONFIG_PATH=${OSS_PREFIX}/lib/pkgconfig ./configure --disable-numa --disable-man-pages --disable-tests --disable-examples --prefix=${OSS_PREFIX} ${XARGS}
    BUILD_COMMAND           make VERBOSE=1
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    libpopt
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    URL                     http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.18.tar.gz
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ./configure -disable-man-pages --disable-tests --disable-examples --disable-shared --enable-static --prefix=${OSS_PREFIX} ${XARGS}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    libuuid
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    URL                     http://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ./configure --disable-shared --enable-static --disable-man-pages --disable-tests --disable-examples --prefix=${OSS_PREFIX} ${XARGS}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)

ExternalProject_Add (
    lttng-tools
    DEPENDS                 lttng-ust libpopt libuuid libxml2
    PREFIX                  ${SRC_PREFIX}
    DOWNLOAD_DIR            ${SRC_DL}
    GIT_REPOSITORY          https://github.com/lttng/lttng-tools.git 
    GIT_TAG                 v2.13.0
    BUILD_IN_SOURCE         1
    CONFIGURE_COMMAND       ./bootstrap && PKG_CONFIG_PATH=${OSS_PREFIX}/lib/pkgconfig ./configure --disable-numa --disable-man-pages --disable-tests --disable-examples --prefix=${OSS_PREFIX} ${XARGS}
    BUILD_COMMAND           make -j4
    INSTALL_COMMAND         make install
)
