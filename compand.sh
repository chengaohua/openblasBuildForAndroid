#!/bin/bash
echo "Build for Android"
APP_ABI="android-9"

OUTPUT_DIR=${PWD}
NDK_ROOT="/opt/android_ndk_r14/android-ndk-r14b"
echo "NDK_ROOT=$NDK_ROOT"
PATHI=$PATH 
if [ ! -d "OpenBLAS" ]; then  
  git clone  https://github.com/xianyi/OpenBLAS.git
fi  

 
if [ -d "OpenBLAS" ]; then
 cd OpenBLAS 
 #fix mips nan format to legacy one
  sed -i 's/-mnan=2008//' Makefile.system
  sed -i 's|#include <complex.h>||' kernel/arm/zdot.c
  sed -i 's|#include <complex.h>||' kernel/mips/zdot.c
  sed -i 's/FLOAT _Complex/OPENBLAS_COMPLEX_FLOAT/' kernel/arm/zdot.c
  sed -i 's/FLOAT _Complex/OPENBLAS_COMPLEX_FLOAT/' kernel/mips/zdot.c
else
    echo "Could not find OpenBLAS directory"
    exit -1
fi 

if [ $1 = "all" ]; then
architectureList=(armeabi armv7a arm64-v8a mips mips64  x86 x86_64 )
else
architectureList=("$@")
fi
 
for architecture in ${architectureList[@]}; do 
    echo ${architecture}
    case ${architecture} in
        "armeabi")
            APP_ABI="android-19"
            target="ARMV5"
            arch="arch-arm"
            CCFolder="arm-linux-androideabi-4.9" 
            CC="arm-linux-androideabi-gcc"
            ;;
        "armv7a")
            APP_ABI="android-19"
            target="ARMV7"
            arch="arch-arm"
            CCFolder="arm-linux-androideabi-4.9"  
            CC="arm-linux-androideabi-gcc ARM_SOFTFP_ABI=1 "
            ;;
        "arm64-v8a")
            APP_ABI="android-21"
            target="ARMV8 BINARY=64"
            arch="arch-arm64"
            CCFolder="aarch64-linux-android-4.9"
            CC="aarch64-linux-android-gcc" 
            ;;
        "mips")
           APP_ABI="android-19"
            target="P5600 AR=mipsel-linux-android-ar "
            arch="arch-mips"
            CCFolder="mipsel-linux-android-4.9"
            CC="mipsel-linux-android-gcc" ;;
        "mips64")
            APP_ABI="android-21"
            target="SICORTEX BINARY=64"
            arch="arch-mips64"
            CCFolder="mips64el-linux-android-4.9"
            CC="mips64el-linux-android-gcc" ;;
        "x86")
            APP_ABI="android-19"
            target="ATOM"
            arch="arch-x86"
            CCFolder="x86-4.9"
            CC="i686-linux-android-gcc" 
             ;;
        "x86_64")
            APP_ABI="android-21"
            target="ATOM BINARY=64"
            arch="arch-x86_64"
            CCFolder="x86_64-4.9"
            CC="x86_64-linux-android-gcc" ;;
        *) 
          echo "UNKNOWN"
          continue
          ;;
    esac

echo ${NDK_ROOT}/toolchains/${CCFolder}/prebuilt/linux-x86_64/bin
export PATH=${NDK_ROOT}/toolchains/${CCFolder}/prebuilt/linux-x86_64/bin:${PATHI}


command="make TARGET=${target} HOSTCC=gcc CC=${CC}  USE_THREAD=0 NOFORTRAN=1 CFLAGS=--sysroot=${NDK_ROOT}/platforms/${APP_ABI}/${arch} "

#ARM_SOFTFP_ABI=1 
#TARGET_CFLAGS += -msoft-float -D_NDK_MATH_NO_SOFTFP=1
#TARGET_LDFLAGS += -Wl,--no-warn-mismatch -lm_hard
echo $command
mkdir -p ../${architecture}
make clean
$command
make PREFIX=${OUTPUT_DIR}/${architecture} install
mv ${OUTPUT_DIR}/${architecture}/lib/*.a ${OUTPUT_DIR}/${architecture}/
rm -rf ${OUTPUT_DIR}/${architecture}/lib
rm -rf ${OUTPUT_DIR}/${architecture}/bin
#if [ ! -d "${OUTPUT_DIR}/include" ]; then
 mv ${OUTPUT_DIR}/${architecture}/include ${OUTPUT_DIR}/${architecture}include/
#else
#	rm -rf ${OUTPUT_DIR}/${architecture}/include
#fi

done
