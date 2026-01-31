# Redroid-rk3588 内核补丁生成脚本

- **[CNflysky/redroid-rk3588](https://github.com/CNflysky/redroid-rk3588) 现已支持 Armbian 原版内核。 因此，本脚本已完成它的使命。**  
- **本项目将不再更新并归档 👋**

## 📋 简介

这个脚本用于自动生成 Armbian RK3588 内核所需的 Redroid 补丁。它通过对比 Armbian 官方内核和 CNflysky 修改过的内核，提取出支持 `system-uncached-dma32` DMA heap 设备的关键差异，并生成可直接应用于 Armbian 编译流程的补丁文件。

## 🎯 为什么需要这个脚本？

### 问题背景

- **Redroid-rk3588** 需要内核提供 `system-uncached-dma32` DMA heap 设备才能正常使用 GPU 硬件加速
- 该设备在 Linux 6.1 主线内核中已被移除
- Armbian 默认内核（rk-6.1-rkr5.1 分支）不包含此设备
- CNflysky 在其 fork 的内核（rk-6.1-rkr4.1 分支）中添加了必要的代码

### 解决方案

手动对比两个内核分支并提取差异工作量巨大且容易出错。这个脚本自动化了整个过程，确保：

✅ 只提取必要的差异（DMA-BUF 相关代码）
✅ 生成符合 Armbian 补丁格式的标准 patch 文件
✅ 可重复执行，便于更新和维护

## 📦 前置要求

### 系统环境
- **操作系统：** Ubuntu 22.04 LTS 或类似 Debian 系发行版
- **内存：** 至少 8GB RAM
- **存储空间：** 至少 15GB 可用空间
- **权限：** 建议以 root 用户运行（避免权限问题）

### 必需工具
```bash
sudo apt update
sudo apt install -y git diffutils coreutils
```

### Armbian 构建环境
脚本需要在已克隆的 Armbian build 目录环境中使用：
```bash
cd ~
git clone --depth=1 https://github.com/armbian/build
```

## 🚀 使用方法

### 1. 获取脚本文件

```bash
cd ~
wget https://github.com/HwlloChen/redroid-rk3588-armbian-kernel-patch/raw/refs/heads/main/generate_redroid_patch.sh
```

### 2. 设置执行权限

```bash
chmod +x generate_redroid_patch.sh
```

### 3. 配置参数（可选）

脚本顶部的配置参数可根据需要修改：

```bash
# Armbian build 目录路径
ARMBIAN_BUILD_DIR="$HOME/build"

# Armbian 目标内核分支（根据你的编译配置调整）
TARGET_KERNEL_BRANCH="rk35xx-vendor-6.1"

# 基准内核分支（Armbian 官方）
ARMBIAN_KERNEL_BRANCH="rk-6.1-rkr5.1"

# 目标内核分支（CNflysky 修改版）
CNFLYSKY_KERNEL_BRANCH="rk-6.1-rkr4.1"
```

**关键参数说明：**

| 参数 | 说明 | 默认值 | 何时修改 |
|------|------|--------|----------|
| `ARMBIAN_BUILD_DIR` | Armbian build 目录路径 | `$HOME/build` | 如果 build 目录在其他位置 |
| `TARGET_KERNEL_BRANCH` | 你的目标内核分支 | `rk35xx-vendor-6.1` | 根据 `./compile.sh` 显示的实际分支名 |
| `ARMBIAN_KERNEL_BRANCH` | Armbian 基准分支 | `rk-6.1-rkr5.1` | 通常无需修改 |
| `CNFLYSKY_KERNEL_BRANCH` | CNflysky 内核分支 | `rk-6.1-rkr4.1` | 通常无需修改 |

### 4. 运行脚本

```bash
./generate_redroid_patch.sh
```

### 5. 验证输出

脚本成功执行后，补丁文件将生成在：
```
~/build/userpatches/kernel/rk35xx-vendor-6.1/0002-dma-uncached-dma32.patch
```

验证补丁内容：
```bash
cat ~/build/userpatches/kernel/rk35xx-vendor-6.1/0002-dma-uncached-dma32.patch
```

## 🔧 工作原理

### 执行流程

```
┌─────────────────────────────────────┐
│ 1. 克隆 Armbian 官方内核 (Base)    │
│    rk-6.1-rkr5.1                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 2. 克隆 CNflysky 内核 (Target)     │
│    rk-6.1-rkr4.1                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 3. 对比指定路径差异                 │
│    - drivers/dma-buf/               │
│    - include/linux/dma-buf.h        │
│    - include/linux/dma-heap.h       │
│    - include/linux/android_kabi.h   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 4. 使用 diff -Nurb 生成统一格式补丁│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ 5. 输出到 Armbian userpatches 目录 │
│    自动应用于后续内核编译           │
└─────────────────────────────────────┘
```

### 关键技术点

1. **精确差异提取：** 只对比 DMA-BUF 相关文件，避免引入不必要的变更
2. **统一补丁格式：** 使用 `diff -Nurb` 生成符合 GNU 标准的补丁
3. **自动集成：** 输出到 `userpatches/kernel/` 目录，Armbian 编译时自动应用

## ❓ 常见问题

### Q1: 脚本运行失败，提示 "克隆失败"

**原因：** 网络问题或 GitHub 访问受限

**解决方案：**
```bash
# 配置 Git 代理（如果使用代理）
git config --global http.proxy http://127.0.0.1:7890

# 或使用 GitHub 镜像站
# 修改脚本中的仓库 URL：
# https://github.com/armbian/linux-rockchip.git
# 改为
# https://mirror.ghproxy.com/https://github.com/armbian/linux-rockchip.git
```

### Q2: 生成的补丁文件为空或很小

**原因：** 内核分支版本不匹配，或文件路径不存在

**解决方案：**
```bash
# 手动验证两个仓库的分支是否存在
git ls-remote https://github.com/armbian/linux-rockchip.git | grep rk-6.1-rkr5.1
git ls-remote https://github.com/CNflysky/linux-rockchip.git | grep rk-6.1-rkr4.1
```

### Q3: Armbian 编译时补丁应用失败

**原因：** 目标内核分支名称配置错误

**解决方案：**
1. 先运行一次 `./compile.sh`，观察实际使用的内核分支名
2. 修改脚本中的 `TARGET_KERNEL_BRANCH` 参数
3. 重新生成补丁

### Q4: 补丁应用后编译内核仍然失败

**原因：** 可能还需要额外的内核配置选项

**解决方案：**
确保内核配置中启用了：
- `CONFIG_ARM64_VA_BITS=39`
- `CONFIG_ANDROID_BINDERFS=y`
- `CONFIG_PSI=y`
- `CONFIG_DMABUF_HEAPS=y`

## 📝 补丁文件说明

生成的补丁文件格式示例：

```diff
From: Redroid Contributor <cnflysky@users.noreply.github.com>
Subject: [PATCH 0002] dma-heap: Add system-uncached-dma32 and necessary files for Redroid GPU

---
diff -Nurb armbian-rkr5.1-base/drivers/dma-buf/dma-heap.c cnflysky-rkr4.1-target/drivers/dma-buf/dma-heap.c
--- armbian-rkr5.1-base/drivers/dma-buf/dma-heap.c	2024-01-01 00:00:00.000000000 +0000
+++ cnflysky-rkr4.1-target/drivers/dma-buf/dma-heap.c	2024-01-01 00:00:00.000000000 +0000
@@ -123,6 +123,9 @@
 	// ... 补丁内容 ...
```

## 🔗 相关资源

- **Armbian 构建文档：** https://docs.armbian.com/Developer-Guide_Build-Preparation/
- **Redroid-rk3588 项目：** https://github.com/CNflysky/redroid-rk3588
- **CNflysky 内核仓库：** https://github.com/CNflysky/linux-rockchip
- **Armbian 内核仓库：** https://github.com/armbian/linux-rockchip

## 📄 许可证

本脚本遵循 [MIT 许可证](LICENSE)。

---

**提示：** 如果在使用过程中遇到问题，建议查看完整的 [RK3588 云手机搭建指南](https://blog.etaris.moe/posts/%E7%94%A8RK3588%E8%AE%BE%E5%A4%87%E6%90%AD%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E4%BA%91%E6%89%8B%E6%9C%BA/)。
