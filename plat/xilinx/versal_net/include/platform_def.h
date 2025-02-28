/*
 * Copyright (c) 2018-2020, ARM Limited and Contributors. All rights reserved.
 * Copyright (c) 2021-2022, Xilinx, Inc. All rights reserved.
 * Copyright (C) 2022, Advanced Micro Devices, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef PLATFORM_DEF_H
#define PLATFORM_DEF_H

#include <arch.h>
#include "versal_net_def.h"

/*******************************************************************************
 * Generic platform constants
 ******************************************************************************/

/* Size of cacheable stacks */
#define PLATFORM_STACK_SIZE		U(0x440)

#define PLATFORM_CLUSTER_COUNT		U(4)
#define PLATFORM_CORE_COUNT_PER_CLUSTER	U(4) /* 4 CPUs per cluster */

#define PLATFORM_CORE_COUNT		(PLATFORM_CLUSTER_COUNT * PLATFORM_CORE_COUNT_PER_CLUSTER)

#define PLAT_MAX_PWR_LVL		U(2)
#define PLAT_MAX_RET_STATE		U(1)
#define PLAT_MAX_OFF_STATE		U(2)

/*******************************************************************************
 * BL31 specific defines.
 ******************************************************************************/
/*
 * Put BL31 at the top of the Trusted SRAM (just below the shared memory, if
 * present). BL31_BASE is calculated using the current BL31 debug size plus a
 * little space for growth.
 */
#ifndef VERSAL_NET_ATF_MEM_BASE
# define BL31_BASE			U(0xBBF00000)
# define BL31_LIMIT			U(0xBBFFFFFF)
#else
# define BL31_BASE			U(VERSAL_NET_ATF_MEM_BASE)
# define BL31_LIMIT			U(VERSAL_NET_ATF_MEM_BASE + VERSAL_NET_ATF_MEM_SIZE - 1)
# ifdef VERSAL_NET_ATF_MEM_PROGBITS_SIZE
#  define BL31_PROGBITS_LIMIT		U(VERSAL_NET_ATF_MEM_BASE + \
					  VERSAL_NET_ATF_MEM_PROGBITS_SIZE - 1)
# endif
#endif

/*******************************************************************************
 * BL32 specific defines.
 ******************************************************************************/
#ifndef VERSAL_NET_BL32_MEM_BASE
# define BL32_BASE			U(0x60000000)
# define BL32_LIMIT			U(0x7FFFFFFF)
#else
# define BL32_BASE			U(VERSAL_NET_BL32_MEM_BASE)
# define BL32_LIMIT			U(VERSAL_NET_BL32_MEM_BASE + VERSAL_NET_BL32_MEM_SIZE - 1)
#endif

/*******************************************************************************
 * BL33 specific defines.
 ******************************************************************************/
#ifndef PRELOADED_BL33_BASE
# define PLAT_ARM_NS_IMAGE_BASE		U(0x8000000)
#else
# define PLAT_ARM_NS_IMAGE_BASE		U(PRELOADED_BL33_BASE)
#endif

/*******************************************************************************
 * TSP  specific defines.
 ******************************************************************************/
#define TSP_SEC_MEM_BASE		BL32_BASE
#define TSP_SEC_MEM_SIZE		(BL32_LIMIT - BL32_BASE + 1U)

/* ID of the secure physical generic timer interrupt used by the TSP */
#define TSP_IRQ_SEC_PHY_TIMER		ARM_IRQ_SEC_PHY_TIMER

/*******************************************************************************
 * Platform specific page table and MMU setup constants
 ******************************************************************************/
#define PLAT_DDR_LOWMEM_MAX		U(0x80000000)

#define PLAT_PHY_ADDR_SPACE_SIZE	(1ULL << 32U)
#define PLAT_VIRT_ADDR_SPACE_SIZE	(1ULL << 32U)
#if (BL31_LIMIT < PLAT_DDR_LOWMEM_MAX)
#define MAX_MMAP_REGIONS		U(10)
#else
#define MAX_MMAP_REGIONS		U(9)
#endif

#define MAX_XLAT_TABLES			U(8)

#define CACHE_WRITEBACK_SHIFT	U(6)
#define CACHE_WRITEBACK_GRANULE	(1 << CACHE_WRITEBACK_SHIFT)

#define PLAT_VERSAL_NET_GICD_BASE	U(0xE2000000)
#define PLAT_VERSAL_NET_GICR_BASE	U(0xE2060000)

/*
 * Define a list of Group 1 Secure and Group 0 interrupts as per GICv3
 * terminology. On a GICv2 system or mode, the lists will be merged and treated
 * as Group 0 interrupts.
 */
#define PLAT_VERSAL_NET_IPI_IRQ	89
#define PLAT_VERSAL_IPI_IRQ	PLAT_VERSAL_NET_IPI_IRQ

#define PLAT_VERSAL_NET_G1S_IRQ_PROPS(grp) \
	INTR_PROP_DESC(VERSAL_NET_IRQ_SEC_PHY_TIMER, GIC_HIGHEST_SEC_PRIORITY, grp, \
			GIC_INTR_CFG_LEVEL)

#define PLAT_VERSAL_NET_G0_IRQ_PROPS(grp) \
	INTR_PROP_DESC(PLAT_VERSAL_IPI_IRQ, GIC_HIGHEST_SEC_PRIORITY, grp, \
			GIC_INTR_CFG_EDGE), \

#endif /* PLATFORM_DEF_H */
