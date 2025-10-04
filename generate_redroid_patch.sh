#!/bin/bash

# --- 配置参数 ---
# 您的 Armbian build 目录路径
ARMBIAN_BUILD_DIR="$HOME/build"
# Armbian 目标内核分支 (来自您的日志)
TARGET_KERNEL_BRANCH="rk35xx-vendor-6.1"
# Armbian 官方内核 rk-6.1 分支 (Base)
ARMBIAN_KERNEL_BRANCH="rk-6.1-rkr5.1"
# CNflysky 带 Redroid 更改的内核分支 (Target)
CNFLYSKY_KERNEL_BRANCH="rk-6.1-rkr4.1"

# 补丁文件路径
PATCH_DIR="${ARMBIAN_BUILD_DIR}/userpatches/kernel/${TARGET_KERNEL_BRANCH}"
PATCH_FILE="0002-dma-uncached-dma32.patch"

# 临时目录
TEMP_DIR_ARMBIAN="armbian-rkr5.1-base"
TEMP_DIR_CNFLYSKY="cnflysky-rkr4.1-target"

# 需要提取差异的目录和文件列表
# 目录差异将递归提取（如 drivers/dma-buf）
# 文件差异将单独提取（如 include/linux/dma-buf.h）
TARGET_PATHS=(
    "drivers/dma-buf"
    "include/linux/dma-buf.h"
    "include/linux/dma-heap.h"
    "include/linux/android_kabi.h"
)
# ------------------

echo "--- 1. 清理环境 ---"
rm -rf ${TEMP_DIR_ARMBIAN} ${TEMP_DIR_CNFLYSKY}
mkdir -p ${PATCH_DIR}

echo "--- 2. 克隆 Armbian Base 内核 (${ARMBIAN_KERNEL_BRANCH}) ---"
git clone --depth 1 -b ${ARMBIAN_KERNEL_BRANCH} https://github.com/armbian/linux-rockchip.git ${TEMP_DIR_ARMBIAN}
if [ $? -ne 0 ]; then echo "❌ 克隆 Armbian 失败。"; exit 1; fi

echo "--- 3. 克隆 CNflysky Target 内核 (${CNFLYSKY_KERNEL_BRANCH}) ---"
git clone --depth 1 -b ${CNFLYSKY_KERNEL_BRANCH} https://github.com/CNflysky/linux-rockchip.git ${TEMP_DIR_CNFLYSKY}
if [ $? -ne 0 ]; then echo "❌ 克隆 CNflysky 失败。"; exit 1; fi

echo "--- 4. 生成补丁头信息 ---"
# 创建补丁文件并写入补丁的描述信息，这是必须的。
{
    echo "From: Redroid Contributor <cnflysky@users.noreply.github.com>"
    echo "Subject: [PATCH 0002] dma-heap: Add system-uncached-dma32 and necessary files for Redroid GPU"
    echo " "
    echo "---"
} > "${PATCH_DIR}/${PATCH_FILE}"

echo "--- 5. 按需提取差异并追加到补丁文件 ---"

for path in "${TARGET_PATHS[@]}"; do
    echo "-> 提取差异: ${path}"
    
    # 使用 diff -Nurb 分别比较每个路径
    # 路径必须以 TEMP_DIR_ARMBIAN/path 和 TEMP_DIR_CNFLYSKY/path 形式提供
    diff -Nurb "${TEMP_DIR_ARMBIAN}/${path}" "${TEMP_DIR_CNFLYSKY}/${path}" >> "${PATCH_DIR}/${PATCH_FILE}"
    
    if [ $? -gt 1 ]; then 
        echo "❌ 提取 ${path} 差异时发生错误，请检查文件是否存在。"
        exit 1
    fi
done

echo "✅ 新的干净补丁已生成并放置在 ${PATCH_DIR}/${PATCH_FILE}"

echo "--- 6. 清理临时文件 ---"
rm -rf ${TEMP_DIR_ARMBIAN} ${TEMP_DIR_CNFLYSKY}

echo -e "\n--- 7. 后续操作 ---"
echo "请确认您的 'userpatches/config/kernel/linux-${TARGET_KERNEL_BRANCH}.config' 中已包含以下配置："
echo "**CONFIG_ARM64_VA_BITS=39**，以及 **CONFIG_ANDROID_BINDERFS=y**, **CONFIG_PSI=y** 等 Redroid 所需项。"
echo ""
echo "现在回到您的 Armbian build 目录并重新运行编译："
echo "    cd ${ARMBIAN_BUILD_DIR}"
echo "    ./compile.sh"
