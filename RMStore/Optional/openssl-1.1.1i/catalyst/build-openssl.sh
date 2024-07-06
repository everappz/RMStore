#!/bin/sh

VERSION="1.1.1i"

#inspired by:
# https://github.com/jasonacox/Build-OpenSSL-cURL

##############################################
SDK_VERSION=`xcrun -sdk macosx --show-sdk-version`
MACOS_X86_64_VERSION="10.15"
CATALYST_IOS_VERSION="13.0"
MACOS_ARM64_VERSION="11.0"

CURRENTPATH=`pwd`
ARCHS="arm64 x86_64"
PLATFORM="MacOSX"
DEVELOPER=`xcode-select -print-path`
##############################################

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in  
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

case $CURRENTPATH in  
     *\ * )
           echo "Your path contains whitespaces, which is not supported by 'make install'."
           exit 1
          ;;
esac

set -e

if [ ! -e openssl-${VERSION}.tar.gz ]; 
then
    wget http://www.openssl.org/source/openssl-${VERSION}.tar.gz
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"


for ARCH in ${ARCHS}
do
	
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"

	echo "Building openssl-${VERSION} for ${PLATFORM} ${SDK_VERSION} ${ARCH}"
	echo "Please stand by..."

	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS_VERSION}-macabi"
	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

    if [[ "${ARCH}" == "x86_64" ]]; then
        export LDFLAGS="-Os -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS_VERSION}-macabi -mmacosx-version-min=${MACOS_X86_64_VERSION}"
        export CFLAGS="-Os -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS_VERSION}-macabi -mmacosx-version-min=${MACOS_X86_64_VERSION}"
        export CPPFLAGS="${CFLAGS} -DNDEBUG"
    fi
    
    if [[ "${ARCH}" == "arm64" ]]; then
        export LDFLAGS="-Os -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS_VERSION}-macabi -mmacosx-version-min=${MACOS_ARM64_VERSION}"
        export CFLAGS="-Os -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS_VERSION}-macabi -mmacosx-version-min=${MACOS_ARM64_VERSION}"
        export CPPFLAGS="${CFLAGS} -I.. -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -DNDEBUG"
    fi

    export CXXFLAGS="${CPPFLAGS}"

	set +e
    
	if [ "${ARCH}" == "x86_64" ]; then
	    ./Configure darwin64-x86_64-cc -no-shared --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk" --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    fi
    
    #https://github.com/openssl/openssl/issues/12254
    if [[ "${ARCH}" == "arm64" ]]; then
	    ./Configure darwin64-arm64-cc -no-shared --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk" --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDK_VERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    fi
    
    if [ $? != 0 ];
    then 
    	echo "Problem while configure - Please check ${LOG}"
    	exit 1
    fi

	if [ "$1" == "verbose" ];
	then
		make -j8
	else
		make -j8 >> "${LOG}" 2>&1
	fi
	
	if [ $? != 0 ];
    then 
    	echo "Problem while make - Please check ${LOG}"
    	exit 1
    fi
    
    set -e
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/MacOSX${SDK_VERSION}-x86_64.sdk/lib/libssl.a ${CURRENTPATH}/bin/MacOSX${SDK_VERSION}-arm64.sdk/lib/libssl.a -output ${CURRENTPATH}/lib/libssl.a

lipo -create ${CURRENTPATH}/bin/MacOSX${SDK_VERSION}-x86_64.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/MacOSX${SDK_VERSION}-arm64.sdk/lib/libcrypto.a -output ${CURRENTPATH}/lib/libcrypto.a

mkdir -p ${CURRENTPATH}/include || true
cp -Rf ${CURRENTPATH}/bin/MacOSX${SDK_VERSION}-x86_64.sdk/include/openssl ${CURRENTPATH}/include/
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src

echo "Done."
