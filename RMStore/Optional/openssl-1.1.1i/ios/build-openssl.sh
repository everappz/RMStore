#!/bin/bash

set -e

# Define OpenSSL version and URL
OPENSSL_VERSION="1.1.1i"
OPENSSL_TARBALL="openssl-${OPENSSL_VERSION}.tar.gz"
OPENSSL_URL="https://www.openssl.org/source/${OPENSSL_TARBALL}"

# Download OpenSSL
if [ ! -e ${OPENSSL_TARBALL} ]; then
    echo "Downloading ${OPENSSL_TARBALL}..."
    curl -O ${OPENSSL_URL}
else
    echo "Using existing ${OPENSSL_TARBALL}..."
fi

# Extract OpenSSL
if [ ! -d "openssl-${OPENSSL_VERSION}" ]; then
    echo "Extracting ${OPENSSL_TARBALL}..."
    tar xzf ${OPENSSL_TARBALL}
else
    echo "Using existing OpenSSL source directory..."
fi

# Define architectures and SDKs
ARCHS=("arm64" "x86_64")
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)

# Define output directories
OUTPUT_DIR="$(pwd)"
BUILD_DIR="$(pwd)/build"
mkdir -p ${OUTPUT_DIR}
mkdir -p ${BUILD_DIR}

# Function to build OpenSSL for a specific architecture and SDK
build_openssl() {
    ARCH=$1
    SDK=$2
    TARGET=$3

    pushd "openssl-${OPENSSL_VERSION}"

    # Clean up previous build
    make clean || true

    # Configure OpenSSL
    if [ "${ARCH}" == "x86_64" ]; then
        ./Configure no-asm darwin64-x86_64-cc --prefix="${BUILD_DIR}/${ARCH}" --openssldir="${BUILD_DIR}/${ARCH}/ssl"
    else
        ./Configure no-asm ios64-cross --prefix="${BUILD_DIR}/${ARCH}" --openssldir="${BUILD_DIR}/${ARCH}/ssl"
    fi

    # Set environment variables
    export CROSS_TOP=$(xcode-select -p)/Platforms/${SDK}.platform/Developer
    export CROSS_SDK=${SDK}.sdk
    export BUILD_TOOLS=$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin

    make CC="${BUILD_TOOLS}/clang" \
         CFLAGS="-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}" \
         LDFLAGS="-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}" \
         -j$(sysctl -n hw.ncpu)

    make install_sw

    popd
}

# Build OpenSSL for each architecture
for ARCH in "${ARCHS[@]}"; do
    if [ "${ARCH}" == "x86_64" ]; then
        build_openssl "${ARCH}" "iPhoneSimulator" "simulator"
    else
        build_openssl "${ARCH}" "iPhoneOS" "device"
    fi
done

# Create a universal binary
echo "Creating universal binary..."
mkdir -p ${OUTPUT_DIR}/lib
lipo -create -output ${OUTPUT_DIR}/lib/libcrypto.a ${BUILD_DIR}/arm64/lib/libcrypto.a ${BUILD_DIR}/x86_64/lib/libcrypto.a
lipo -create -output ${OUTPUT_DIR}/lib/libssl.a ${BUILD_DIR}/arm64/lib/libssl.a ${BUILD_DIR}/x86_64/lib/libssl.a

# Copy headers
mkdir -p ${OUTPUT_DIR}/include
cp -R ${BUILD_DIR}/arm64/include/openssl ${OUTPUT_DIR}/include

echo "Build completed successfully!"