# Redroid-rk3588 Kernel Patch Generation Script

[中文版本](README_zh-cn.md)

## 📋 Introduction

This script automatically generates the required Redroid kernel patches for Armbian RK3588. By comparing the official Armbian kernel with CNflysky's modified kernel, it extracts key differences that add support for the `system-uncached-dma32` DMA heap device and generates a patch file that can be directly applied to the Armbian build process.

## 🎯 Why Do You Need This Script?

### Background

- **Redroid-rk3588** requires the kernel to provide the `system-uncached-dma32` DMA heap device for GPU hardware acceleration
- This device was removed from the mainline Linux 6.1 kernel
- Armbian's default kernel (rk-6.1-rkr5.1 branch) does not include this device
- CNflysky added the necessary code in their forked kernel (rk-6.1-rkr4.1 branch)

### Solution

Manually comparing two kernel branches and extracting differences is time-consuming and error-prone. This script automates the entire process, ensuring:

✅ Extract only necessary differences (DMA-BUF related code)
✅ Generate standard patch files conforming to Armbian patch format
✅ Repeatable execution for easy updates and maintenance

## 📦 Prerequisites

### System Environment
- **Operating System:** Ubuntu 22.04 LTS or similar Debian-based distributions
- **Memory:** At least 8GB RAM
- **Storage:** At least 15GB free space
- **Privileges:** Recommended to run as root user (to avoid permission issues)

### Required Tools
```bash
sudo apt update
sudo apt install -y git diffutils coreutils
```

### Armbian Build Environment
The script needs to be used within a cloned Armbian build directory:
```bash
cd ~
git clone --depth=1 https://github.com/armbian/build
```

## 🚀 Usage

### 1. Create Script File

```bash
cd ~
touch generate_redroid_patch.sh
chmod +x generate_redroid_patch.sh
```

### 2. Edit Script Content

Copy the script code into the file (using vim, nano, or other editors):

```bash
vim generate_redroid_patch.sh
```

### 3. Configure Parameters (Optional)

Configuration parameters at the top of the script can be modified as needed:

```bash
# Armbian build directory path
ARMBIAN_BUILD_DIR="$HOME/build"

# Armbian target kernel branch (adjust according to your build configuration)
TARGET_KERNEL_BRANCH="rk35xx-vendor-6.1"

# Base kernel branch (Armbian official)
ARMBIAN_KERNEL_BRANCH="rk-6.1-rkr5.1"

# Target kernel branch (CNflysky modified version)
CNFLYSKY_KERNEL_BRANCH="rk-6.1-rkr4.1"
```

**Key Parameter Descriptions:**

| Parameter | Description | Default Value | When to Modify |
|-----------|-------------|---------------|----------------|
| `ARMBIAN_BUILD_DIR` | Armbian build directory path | `$HOME/build` | If build directory is in another location |
| `TARGET_KERNEL_BRANCH` | Your target kernel branch | `rk35xx-vendor-6.1` | Based on actual branch name shown by `./compile.sh` |
| `ARMBIAN_KERNEL_BRANCH` | Armbian base branch | `rk-6.1-rkr5.1` | Usually no need to modify |
| `CNFLYSKY_KERNEL_BRANCH` | CNflysky kernel branch | `rk-6.1-rkr4.1` | Usually no need to modify |

### 4. Run the Script

```bash
./generate_redroid_patch.sh
```

### 5. Verify Output

After successful execution, the patch file will be generated at:
```
~/build/userpatches/kernel/rk35xx-vendor-6.1/0002-dma-uncached-dma32.patch
```

Verify patch content:
```bash
cat ~/build/userpatches/kernel/rk35xx-vendor-6.1/0002-dma-uncached-dma32.patch
```

## 🔧 How It Works

### Execution Flow

```
┌─────────────────────────────────────┐
│ 1. Clone Armbian Official Kernel   │
│    (Base) rk-6.1-rkr5.1             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 2. Clone CNflysky Kernel (Target)   │
│    rk-6.1-rkr4.1                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 3. Compare Specified Path Diffs     │
│    - drivers/dma-buf/               │
│    - include/linux/dma-buf.h        │
│    - include/linux/dma-heap.h       │
│    - include/linux/android_kabi.h   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 4. Generate Unified Format Patch    │
│    Using diff -Nurb                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 5. Output to Armbian userpatches/   │
│    Auto-applied to kernel builds    │
└─────────────────────────────────────┘
```

### Key Technical Points

1. **Precise Diff Extraction:** Only compare DMA-BUF related files to avoid unnecessary changes
2. **Unified Patch Format:** Use `diff -Nurb` to generate GNU standard patches
3. **Automatic Integration:** Output to `userpatches/kernel/` directory, automatically applied during Armbian compilation

## ❓ FAQ

### Q1: Script fails with "Clone failed" error

**Cause:** Network issues or GitHub access restrictions

**Solution:**
```bash
# Configure Git proxy (if using proxy)
git config --global http.proxy http://127.0.0.1:7890

# Or use GitHub mirror
# Modify repository URLs in the script:
# https://github.com/armbian/linux-rockchip.git
# Change to
# https://mirror.ghproxy.com/https://github.com/armbian/linux-rockchip.git
```

### Q2: Generated patch file is empty or very small

**Cause:** Kernel branch version mismatch, or file paths don't exist

**Solution:**
```bash
# Manually verify if branches exist in both repositories
git ls-remote https://github.com/armbian/linux-rockchip.git | grep rk-6.1-rkr5.1
git ls-remote https://github.com/CNflysky/linux-rockchip.git | grep rk-6.1-rkr4.1
```

### Q3: Patch application fails during Armbian compilation

**Cause:** Target kernel branch name configured incorrectly

**Solution:**
1. Run `./compile.sh` once and observe the actual kernel branch name used
2. Modify the `TARGET_KERNEL_BRANCH` parameter in the script
3. Regenerate the patch

### Q4: Kernel compilation still fails after applying patch

**Cause:** Additional kernel configuration options may be required

**Solution:**
Ensure the following are enabled in kernel configuration:
- `CONFIG_ARM64_VA_BITS=39`
- `CONFIG_ANDROID_BINDERFS=y`
- `CONFIG_PSI=y`
- `CONFIG_DMABUF_HEAPS=y`

## 📝 Patch File Description

Example of generated patch file format:

```diff
From: Redroid Contributor <cnflysky@users.noreply.github.com>
Subject: [PATCH 0002] dma-heap: Add system-uncached-dma32 and necessary files for Redroid GPU

---
diff -Nurb armbian-rkr5.1-base/drivers/dma-buf/dma-heap.c cnflysky-rkr4.1-target/drivers/dma-buf/dma-heap.c
--- armbian-rkr5.1-base/drivers/dma-buf/dma-heap.c	2024-01-01 00:00:00.000000000 +0000
+++ cnflysky-rkr4.1-target/drivers/dma-buf/dma-heap.c	2024-01-01 00:00:00.000000000 +0000
@@ -123,6 +123,9 @@
 	// ... patch content ...
```

## 🔗 Related Resources

- **Armbian Build Documentation:** https://docs.armbian.com/Developer-Guide_Build-Preparation/
- **Redroid-rk3588 Project:** https://github.com/CNflysky/redroid-rk3588
- **CNflysky Kernel Repository:** https://github.com/CNflysky/linux-rockchip
- **Armbian Kernel Repository:** https://github.com/armbian/linux-rockchip

## 📄 License

This script is licensed under [MIT License](LICENSE).

---

**Tip:** If you encounter issues during usage, please refer to the complete [RK3588 Cloud Phone Setup Guide](https://blog.etaris.moe/posts/%E7%94%A8RK3588%E8%AE%BE%E5%A4%87%E6%90%AD%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E4%BA%91%E6%89%8B%E6%9C%BA/).
