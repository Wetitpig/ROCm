#!/bin/bash

set -ex

source "$(dirname "${BASH_SOURCE[0]}")/compute_helper.sh"

set_component_src composable_kernel

build_miopen_ck() {
    echo "Start Building Composable Kernel"
    if [ "${ENABLE_ADDRESS_SANITIZER}" == "true" ]; then
       set_asan_env_vars
       set_address_sanitizer_on
    fi

    cd $COMPONENT_SRC
    mkdir "$BUILD_DIR" && cd "$BUILD_DIR"

    if [ -n "$GPU_ARCHS" ]; then
        GPU_TARGETS="-DGPU_TARGETS=${GPU_ARCHS}"
    fi

    if [ "${ASAN_CMAKE_PARAMS}" == "true" ] ; then
        cmake -DBUILD_DEV=OFF \
            -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-'RelWithDebInfo'} \
            -DCMAKE_CXX_COMPILER=${ROCM_PATH}/llvm/bin/clang++ \
            -DCMAKE_CXX_FLAGS=" -O3 " \
            -DCMAKE_PREFIX_PATH="${ROCM_PATH%-*}/lib/cmake;${ROCM_PATH%-*}/$ASAN_LIBDIR;${ROCM_PATH%-*}/llvm;${ROCM_PATH%-*}" \
            -DCMAKE_SHARED_LINKER_FLAGS_INIT="-Wl,--enable-new-dtags,--rpath,$ROCM_ASAN_LIB_RPATH" \
            -DCMAKE_EXE_LINKER_FLAGS_INIT="-Wl,--enable-new-dtags,--rpath,$ROCM_ASAN_EXE_RPATH" \
            -DCMAKE_VERBOSE_MAKEFILE=1 \
            -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
            -DCMAKE_INSTALL_PREFIX=${ROCM_PATH} \
            -DCMAKE_PACKAGING_INSTALL_PREFIX=${ROCM_PATH} \
            -DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF \
            -DROCM_SYMLINK_LIBS=OFF \
            -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_PATH} \
            -DROCM_DISABLE_LDCONFIG=ON \
            -DROCM_PATH=${ROCM_PATH} \
            -DCPACK_GENERATOR="${PKGTYPE^^}" \
            ${LAUNCHER_FLAGS} \
            -DINSTANCES_ONLY=ON \
            -DENABLE_ASAN_PACKAGING=true \
            "${GPU_TARGETS}" \
            "$COMPONENT_SRC"
    else
        cmake -DBUILD_DEV=OFF \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_COMPILER=${ROCM_PATH}/llvm/bin/clang++ \
            -DCMAKE_CXX_FLAGS=" -O3 " \
            -DCMAKE_PREFIX_PATH=${ROCM_PATH%-*} \
            -DCMAKE_SHARED_LINKER_FLAGS_INIT='-Wl,--enable-new-dtags,--rpath,$ORIGIN' \
            -DCMAKE_EXE_LINKER_FLAGS_INIT='-Wl,--enable-new-dtags,--rpath,$ORIGIN/../lib' \
            -DCMAKE_VERBOSE_MAKEFILE=1 \
            -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
            -DCMAKE_INSTALL_PREFIX=${ROCM_PATH} \
            -DCMAKE_PACKAGING_INSTALL_PREFIX=${ROCM_PATH} \
            -DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF \
            -DROCM_SYMLINK_LIBS=OFF \
            -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_PATH} \
            -DROCM_DISABLE_LDCONFIG=ON \
            -DROCM_PATH=${ROCM_PATH} \
            -DCPACK_GENERATOR="${PKGTYPE^^}" \
            -DCMAKE_CXX_COMPILER="${ROCM_PATH}/llvm/bin/clang++" \
            -DCMAKE_C_COMPILER="${ROCM_PATH}/llvm/bin/clang" \
            ${LAUNCHER_FLAGS} \
            -DINSTANCES_ONLY=ON \
            "${GPU_TARGETS}" \
            "$COMPONENT_SRC"
    fi

    cmake --build . -- -j${PROC} package
    cmake --build "$BUILD_DIR" -- install
    mkdir -p $PACKAGE_DIR && cp ./*.${PKGTYPE} $PACKAGE_DIR
    rm -rf *
}

unset_asan_env_vars() {
    ASAN_CMAKE_PARAMS="false"
    export ADDRESS_SANITIZER="OFF"
    export LD_LIBRARY_PATH=""
    export ASAN_OPTIONS=""
}

set_address_sanitizer_off() {
    export CFLAGS=""
    export CXXFLAGS=""
    export LDFLAGS=""
}

build_miopen_ckProf() {
    ENABLE_ADDRESS_SANITIZER=false
    echo "Start Building Composable Kernel Profiler"
    if [ "${ENABLE_ADDRESS_SANITIZER}" == "true" ]; then
       set_asan_env_vars
       set_address_sanitizer_on
    else
       unset_asan_env_vars
       set_address_sanitizer_off
    fi

    cd $COMPONENT_SRC
    cd "$BUILD_DIR"
    rm -rf *

    architectures='gfx10 gfx11 gfx90 gfx94'
    if [ -n "$GPU_ARCHS" ]; then
        architectures=$(echo ${GPU_ARCHS} | awk -F';' '{for(i=1;i<=NF;i++) a[substr($i,1,5)]} END{for(i in a) printf i" "}')
    fi

    for arch in ${architectures}
        do
            if [ "${ASAN_CMAKE_PARAMS}" == "true" ] ; then
                cmake -DBUILD_DEV=OFF \
                    -DCMAKE_PREFIX_PATH="${ROCM_PATH%-*}/lib/cmake;${ROCM_PATH%-*}/$ASAN_LIBDIR;${ROCM_PATH%-*}/llvm;${ROCM_PATH%-*}" \
                    -DCMAKE_BUILD_TYPE=${BUILD_TYPE:-'RelWithDebInfo'} \
                    -DCMAKE_SHARED_LINKER_FLAGS_INIT="-Wl,--enable-new-dtags,--rpath,$ROCM_ASAN_LIB_RPATH" \
                    -DCMAKE_EXE_LINKER_FLAGS_INIT="-Wl,--enable-new-dtags,--rpath,$ROCM_ASAN_EXE_RPATH" \
                    -DCMAKE_VERBOSE_MAKEFILE=1 \
                    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
                    -DCMAKE_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DCMAKE_PACKAGING_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF \
                    -DROCM_SYMLINK_LIBS=OFF \
                    -DCPACK_PACKAGING_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DROCM_DISABLE_LDCONFIG=ON \
                    -DROCM_PATH="${ROCM_PATH}" \
                    -DCPACK_GENERATOR="${PKGTYPE^^}" \
                    -DCMAKE_CXX_COMPILER="${ROCM_PATH}/llvm/bin/clang++" \
                    -DCMAKE_C_COMPILER="${ROCM_PATH}/llvm/bin/clang" \
                    ${LAUNCHER_FLAGS} \
                    -DPROFILER_ONLY=ON \
                    -DENABLE_ASAN_PACKAGING=true \
                    -DGPU_ARCH="${arch}" \
                    "$COMPONENT_SRC"
            else
                cmake -DBUILD_DEV=OFF \
                    -DCMAKE_PREFIX_PATH="${ROCM_PATH%-*}" \
                    -DCMAKE_BUILD_TYPE=Release \
                    -DCMAKE_SHARED_LINKER_FLAGS_INIT='-Wl,--enable-new-dtags,--rpath,$ORIGIN' \
                    -DCMAKE_EXE_LINKER_FLAGS_INIT='-Wl,--enable-new-dtags,--rpath,$ORIGIN/../lib' \
                    -DCMAKE_VERBOSE_MAKEFILE=1 \
                    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
                    -DCMAKE_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DCMAKE_PACKAGING_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF \
                    -DROCM_SYMLINK_LIBS=OFF \
                    -DCPACK_PACKAGING_INSTALL_PREFIX="${ROCM_PATH}" \
                    -DROCM_DISABLE_LDCONFIG=ON \
                    -DROCM_PATH="${ROCM_PATH}" \
                    -DCPACK_GENERATOR="${PKGTYPE^^}" \
                    -DCMAKE_CXX_COMPILER="${ROCM_PATH}/llvm/bin/clang++" \
                    -DCMAKE_C_COMPILER="${ROCM_PATH}/llvm/bin/clang" \
                    ${LAUNCHER_FLAGS} \
                    -DPROFILER_ONLY=ON \
                    -DGPU_ARCH="${arch}" \
                    "$COMPONENT_SRC"
            fi

            cmake --build . -- -j${PROC} package
            cp ./*ckprofiler*.${PKGTYPE} $PACKAGE_DIR
            rm -rf *
        done
    rm -rf _CPack_Packages/ && find -name '*.o' -delete

    echo "Finished building Composable Kernel"
    show_build_cache_stats
}

clean_miopen_ck() {
    echo "Cleaning MIOpen-CK build directory: ${BUILD_DIR} ${PACKAGE_DIR}"
    rm -rf "$BUILD_DIR" "$PACKAGE_DIR"
    echo "Done!"
}

stage2_command_args "$@"

case $TARGET in
    build) build_miopen_ck; build_miopen_ckProf;;
    outdir) print_output_directory ;;
    clean) clean_miopen_ck ;;
    *) die "Invalid target $TARGET" ;;
esac
