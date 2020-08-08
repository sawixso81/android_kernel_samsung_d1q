#!/bin/bash
# Afaneh menu V1.0 

# Variables
DIR=`readlink -f .`;
PARENT_DIR=`readlink -f ${DIR}/..`;

CHIPSET_NAME=sm8150
ARCH=arm64

BUILD_CROSS_COMPILE=$PARENT_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$PARENT_DIR/llvm-arm-toolchain-ship_8.0.6/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

DTS_DIR=$(pwd)/out/arch/$ARCH/boot/dts

RED='\033[0;41;30m'
STD='\033[0;0;39m'

# Functions
pause(){
  read -p "Press [Enter] key to $*..." fackEnterKey
}

toolchain(){
  if [ ! -d $PARENT_DIR/aarch64-linux-android-4.9 ]; then
    pause 'clone Toolchain aarch64-linux-android-4.9 cross compiler'
    git clone https://android.googlesource.com/PLATFORM/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $PARENT_DIR/aarch64-linux-android-4.9
    . $DIR/build_menu.sh
  fi
}

llvm(){
  if [ ! -d $PARENT_DIR/llvm-arm-toolchain-ship_8.0.6 ]; then
    pause 'clone Snapdragon LLVM ARM Compiler 8.0'
    git clone https://github.com/zhuec/android_vendor_qcom_proprietary_llvm-arm-toolchain-ship_8.0.6 $PARENT_DIR/llvm-arm-toolchain-ship_8.0.6
    . $DIR/build_menu.sh
  fi
}

clean(){
  DTBO_FILES=$(find ${DTS_DIR}/samsung/ -name ${CHIPSET_NAME}-sec-*-r*.dtbo)
  rm ${DTS_DIR}/qcom/*.dtb ${DTBO_FILES}

  make CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE clean 
  make CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE mrproper
  if [ -d "out" ]; then
    rm -rf out
  fi
  pause 'continue'
 }

build(){
  if [ ! -d "out" ]; then
    mkdir out
  fi

  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN d1q_defconfig
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN

  cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image
  cp out/arch/arm64/boot/Image-dtb $(pwd)/out/Image-dtb

  DTBO_FILES=$(find ${DTS_DIR}/samsung/ -name ${CHIPSET_NAME}-sec-*-r*.dtbo)

  cat ${DTS_DIR}/qcom/*.dtb > $(pwd)/out/dtb.img
  $(pwd)/tools/mkdtimg create $(pwd)/out/dtbo.img --page_size=4096 ${DTBO_FILES}
  pause 'continue'
}

anykernel3(){
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    pause 'clone AnyKernel3 - Flashable Zip Template'
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  [ -e $PARENT_DIR/d1q_usa_single_Kernel.zip ] && rm $PARENT_DIR/d1q_usa_single_Kernel.zip
  cp out/arch/arm64/boot/Image-dtb $PARENT_DIR/AnyKernel3/zImage
  cd $PARENT_DIR/AnyKernel3
  git reset --hard
  sed -i 's/ExampleKernel by osm0sis/d1q_Kernel by afaneh92/g' anykernel.sh
  sed -i 's/=maguro/=d1q/g' anykernel.sh
  sed -i 's/=toroplus/=/g' anykernel.sh
  sed -i 's/=toro/=/g' anykernel.sh
  sed -i 's/=tuna/=/g' anykernel.sh
  sed -i 's/omap\/omap_hsmmc\.0\/by-name\/boot/soc\/1d84000\.ufshc\/by-name\/boot/g' anykernel.sh
  sed -i 's/backup_file/#backup_file/g' anykernel.sh
  sed -i 's/replace_string/#replace_string/g' anykernel.sh
  sed -i 's/insert_line/#insert_line/g' anykernel.sh
  sed -i 's/append_file/#append_file/g' anykernel.sh
  sed -i 's/patch_fstab/#patch_fstab/g' anykernel.sh
  zip -r9 $PARENT_DIR/d1q_usa_single_Kernel.zip * -x .git README.md *placeholder
  cd $DIR
  pause 'continue'
}

# Run once
toolchain
llvm

# Show menu
show_menus() {
  clear
  echo "~~~~~~~~~~~~~~~~~~~~~"	
  echo " M A I N - M E N U"
  echo "~~~~~~~~~~~~~~~~~~~~~"
  echo "1. Build"
  echo "2. Clean"
  echo "3. Make flashable zip"
  echo "4. Exit"
}

# Read input
read_options(){
  local choice
  read -p "Enter choice [ 1 - 4] " choice
  case $choice in
    1) build ;;
    2) clean ;;
    3) anykernel3;;
    4) exit 0;;
    *) echo -e "${RED}Error...${STD}" && sleep 2
  esac
}

# Trap CTRL+C, CTRL+Z and quit singles
trap '' SIGINT SIGQUIT SIGTSTP

# Step # Main logic - infinite loop
while true
do
  show_menus
  read_options
done
