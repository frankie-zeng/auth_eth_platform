CURR_FILE_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
TOP_DIR:=$(shell dirname $(CURR_FILE_PATH))

KERNEL_NAME:=linux
KERNEL_DIR:=${shell pwd}/${KERNEL_NAME}

ROOTFS_DIR:=${TOP_DIR}/rootfs
BOOT_DIR:=${TOP_DIR}/boot


$(shell mkdir -p ${BOOT_DIR})
$(shell mkdir -p ${BOOT_DIR}/overlays)
$(shell mkdir -p ${ROOTFS_DIR})


#bcm2711_ptp_defconfig
KERNEL_CONFIG:=bcm2711_defconfig
# KERNEL_CONFIG:=defconfig
ARCH:=arm64
CROSS_COMPILE:=aarch64-linux-gnu-
KERNEL:=kernel8


.PHONY:all
all: kernel igb kernel_module

saveconfig:
	cd ${KERNEL_NAME}; \
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} savedefconfig O=build

menuconfig:
	cd ${KERNEL_NAME} ;[ ! -f build/.config ] && make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} ${KERNEL_CONFIG} O=build ; \
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} menuconfig -j 8 O=build

kernel:
	cd ${KERNEL_NAME} ;[ ! -f build/.config ] && make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} ${KERNEL_CONFIG} O=build ; \
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image modules dtbs -j 8 O=build || exit ; \
	cp build/arch/arm64/boot/Image ${BOOT_DIR} ; \
	mv ${BOOT_DIR}/Image ${BOOT_DIR}/${KERNEL}.img ;\
	cp build/arch/arm64/boot/dts/broadcom/*.dtb ${BOOT_DIR} ;\
	cp arch/arm64/boot/dts/overlays/README ${BOOT_DIR} ;\
	cp build/arch/arm64/boot/dts/overlays/*.dtb* ${BOOT_DIR}/overlays

kernel_module:
	cd ${KERNEL_NAME};[ ! -f build/.config ] && echo -e "\033[31m.config is nonexist, Please exec \"make kernel\" \033[0m" && exit 1; \
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} INSTALL_MOD_PATH=${ROOTFS_DIR} modules_install O=build


kernel/clean:
	cd ${KERNEL_NAME}; make ARCH=${ARCH} O=build mrproper || exit
	rm -rf target/*


# IGB_AVB

igb: igb_kmod igb_lib

igb_clean: igb_kmod_clean igb_lib_clean

igb_install: igb_kmod_install


igb_kmod_install:
	cd igb_avb/kmod ; \
	make CC=aarch64-linux-gnu-gcc CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KSRC=${KERNEL_DIR} INSTALL_MOD_PATH=${ROOTFS_DIR} modules_install O=build

##TODO igb lib install

igb_kmod_clean:
	cd igb_avb/kmod ; \
	make CC=aarch64-linux-gnu-gcc CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KSRC=${KERNEL_DIR} O=build clean

igb_lib_clean:
	cd igb_avb/lib ; \
	make clean


igb_kmod:
	cd igb_avb/kmod ; \
	make CC=aarch64-linux-gnu-gcc CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KSRC=${KERNEL_DIR} O=build

igb_lib:
	cd igb_avb/lib ; \
	make CC=aarch64-linux-gnu-gcc RANLIB=aarch64-linux-gnu-ranlib


# clean 



clean:  kernel/clean 