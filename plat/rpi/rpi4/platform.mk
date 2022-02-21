#
# Copyright (c) 2013-2021, ARM Limited and Contributors. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

include lib/libfdt/libfdt.mk
include lib/xlat_tables_v2/xlat_tables.mk

include drivers/arm/gic/v2/gicv2.mk

PLAT_INCLUDES		:=	-Iplat/rpi/common/include		\
				-Iplat/rpi/rpi4/include

PLAT_BL_COMMON_SOURCES	:=	drivers/ti/uart/aarch64/16550_console.S	\
				drivers/arm/pl011/aarch64/pl011_console.S \
				drivers/gpio/gpio.c			\
				drivers/delay_timer/delay_timer.c	\
				drivers/rpi3/gpio/rpi3_gpio.c		\
				plat/rpi/common/aarch64/plat_helpers.S	\
				plat/rpi/common/rpi3_common.c		\
				${XLAT_TABLES_LIB_SRCS}

BL1_SOURCES		+=	drivers/io/io_fip.c			\
				drivers/io/io_memmap.c			\
				drivers/io/io_storage.c			\
				lib/cpus/aarch64/cortex_a72.S		\
				plat/common/aarch64/platform_mp_stack.S	\
				plat/rpi/rpi4/rpi4_bl1_setup.c		\
				plat/rpi/common/rpi3_io_storage.c

BL2_SOURCES		+=	common/desc_image_load.c		\
				drivers/io/io_fip.c			\
				drivers/io/io_memmap.c			\
				drivers/io/io_storage.c			\
				drivers/delay_timer/generic_delay_timer.c \
				drivers/io/io_block.c			\
				plat/common/aarch64/platform_mp_stack.S	\
				plat/rpi/rpi3/aarch64/rpi3_bl2_mem_params_desc.c \
				plat/rpi/rpi4/rpi4_bl2_setup.c		\
				plat/rpi/common/rpi3_image_load.c	\
				plat/rpi/common/rpi3_io_storage.c

BL31_SOURCES		+=	lib/cpus/aarch64/cortex_a72.S		\
				plat/common/plat_gicv2.c                \
				plat/rpi/rpi4/rpi4_bl31_setup.c		\
				plat/rpi/common/rpi3_pm.c		\
				plat/common/plat_psci_common.c		\
				plat/rpi/common/rpi3_topology.c		\
				common/fdt_fixup.c			\
				${LIBFDT_SRCS}				\
				${GICV2_SOURCES}

# For now we only support BL31, using the kernel loaded by the GPU firmware.
RESET_TO_BL31		:=	0

# All CPUs enter armstub8.bin.
COLD_BOOT_SINGLE_CPU	:=	0

# Tune compiler for Cortex-A72
ifeq ($(notdir $(CC)),armclang)
    TF_CFLAGS_aarch64	+=	-mcpu=cortex-a72
else ifneq ($(findstring clang,$(notdir $(CC))),)
    TF_CFLAGS_aarch64	+=	-mcpu=cortex-a72
else
    TF_CFLAGS_aarch64	+=	-mtune=cortex-a72
endif

# Add support for platform supplied linker script for BL31 build
#$(eval $(call add_define,PLAT_EXTRA_LD_SCRIPT))

# Enable all errata workarounds for Cortex-A72
ERRATA_A72_859971		:= 1
ERRATA_A72_1319367		:= 1

WORKAROUND_CVE_2017_5715	:= 1

RPI3_BL1_PAD_BIN	:=	${BUILD_PLAT}/bl1_pad.bin
RPI3_ARMSTUB8_BIN	:=	${BUILD_PLAT}/armstub8.bin

# Add new default target when compiling this platform
# Add new default target when compiling this platform
all: armstub

# This target concatenates BL1 and the FIP so that the base addresses match the
# ones defined in the memory map
armstub: bl1 fip
	@echo "  CAT     $@"
	${Q}cp ${BUILD_PLAT}/bl1.bin ${RPI3_BL1_PAD_BIN}
	${Q}truncate --size=131072 ${RPI3_BL1_PAD_BIN}
	${Q}cat ${RPI3_BL1_PAD_BIN} ${BUILD_PLAT}/fip.bin > ${RPI3_ARMSTUB8_BIN}
	@${ECHO_BLANK_LINE}
	@echo "Built $@ successfully"
	@${ECHO_BLANK_LINE}

# Build config flags
# ------------------

# Disable stack protector by default
ENABLE_STACK_PROTECTOR	 	:= 0

# Have different sections for code and rodata
SEPARATE_CODE_AND_RODATA	:= 1

# Use Coherent memory
USE_COHERENT_MEM		:= 1

# Platform build flags
# --------------------

# There is not much else than a Linux kernel to load at the moment.
RPI3_DIRECT_LINUX_BOOT		:= 1

# BL33 images are in AArch64 by default
RPI3_BL33_IN_AARCH32		:= 0

# UART to use at runtime. -1 means the runtime UART is disabled.
# Any other value means the default UART will be used.
RPI3_RUNTIME_UART		:= -1

# Use normal memory mapping for ROM, FIP, SRAM and DRAM
RPI3_USE_UEFI_MAP		:= 0

# SMCCC PCI support (should be enabled for ACPI builds)
SMC_PCI_SUPPORT            	:= 0

# BL32 location
RPI3_BL32_RAM_LOCATION	:= tdram
ifeq (${RPI3_BL32_RAM_LOCATION}, tsram)
  RPI3_BL32_RAM_LOCATION_ID = SEC_SRAM_ID
else ifeq (${RPI3_BL32_RAM_LOCATION}, tdram)
  RPI3_BL32_RAM_LOCATION_ID = SEC_DRAM_ID
else
  $(error "Unsupported RPI3_BL32_RAM_LOCATION value")
endif

# Process platform flags
# ----------------------

$(eval $(call add_define,RPI3_BL32_RAM_LOCATION_ID))
$(eval $(call add_define,RPI3_BL33_IN_AARCH32))
$(eval $(call add_define,RPI3_DIRECT_LINUX_BOOT))
ifdef RPI3_PRELOADED_DTB_BASE
$(eval $(call add_define,RPI3_PRELOADED_DTB_BASE))
endif
$(eval $(call add_define,RPI3_RUNTIME_UART))
$(eval $(call add_define,RPI3_USE_UEFI_MAP))
$(eval $(call add_define,SMC_PCI_SUPPORT))

ifeq (${ARCH},aarch32)
  $(error Error: AArch32 not supported on rpi4)
endif

ifneq ($(ENABLE_STACK_PROTECTOR), 0)
PLAT_BL_COMMON_SOURCES	+=	drivers/rpi3/rng/rpi3_rng.c		\
				plat/rpi/common/rpi3_stack_protector.c
endif

ifeq (${SPD},opteed)
BL2_SOURCES	+=							\
		lib/optee/optee_utils.c
endif

# Add the build options to pack Trusted OS Extra1 and Trusted OS Extra2 images
# in the FIP if the platform requires.
ifneq ($(BL32_EXTRA1),)
$(eval $(call TOOL_ADD_IMG,BL32_EXTRA1,--tos-fw-extra1))
endif
ifneq ($(BL32_EXTRA2),)
$(eval $(call TOOL_ADD_IMG,BL32_EXTRA2,--tos-fw-extra2))
endif

ifeq ($(SMC_PCI_SUPPORT), 1)
BL31_SOURCES            +=      plat/rpi/rpi4/rpi4_pci_svc.c
endif
