#!/bin/sh

# path to kernel sources
KERNEL_SRC_PATH=~/android_kernel_sony_msm8974/

echo "generating device tree..."
./dtbTool -o dt.img -s 2048 -p {KERNEL_SRC_PATH}/scripts/dtc/ {KERNEL_SRC_PATH}/arch/arm/boot/
