#!/bin/bash
set -e
set -o pipefail

mkdir -p armbian
mkdir -p output

# 读取环境变量 (带默认值)
VERSION_TYPE="${VERSION_TYPE:-standard}"
echo "构建版本: $VERSION_TYPE"

# 根据版本选择文件名
case "$VERSION_TYPE" in
  debian13_minimal)
    FILE_NAME="Armbian_26.2.6_Uefi-x86_trixie_current_6.18.26_minimal.img.xz"
    ;;
  ubuntu24_minimal)
    FILE_NAME="Armbian_26.2.6_Uefi-x86_noble_current_6.18.26_minimal.img.xz"
    ;;
  ubuntu26_minimal)
    FILE_NAME="Armbian_26.2.6_Uefi-x86_resolute_current_6.18.26_minimal.img.xz"
    ;;
  *)
    FILE_NAME="Armbian_26.2.6_Uefi-x86_noble_current_6.18.26_minimal.img.xz"
    ;;
esac

# 固定下载前缀
BASE_URL="https://mirrors.nju.edu.cn/armbian-releases/uefi-x86/archive/"
DOWNLOAD_URL="${BASE_URL}${FILE_NAME}"
OUTPUT_PATH="armbian/armbian.img.xz"

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"

# 下载文件
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"
echo "下载完成!"
file "$OUTPUT_PATH"

# 解压镜像
echo "正在解压为: armbian.img ..."
xz -d -T0 "$OUTPUT_PATH"  # 使用所有 CPU 线程

if [[ ! -f armbian/armbian.img ]]; then
  echo "错误：armbian.img 不存在，无法启动 Docker 构建"
  exit 1
fi
ls -lh armbian/

# Docker 构建 ISO
echo "准备通过 Docker 构建 Armbian 安装器 ISO..."
docker run --privileged --rm \
  -v $(pwd)/output:/output \
  -v $(pwd)/supportFiles:/supportFiles:ro \
  -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
  debian:buster bash -c "apt update && apt install -y xz-utils && /supportFiles/build.sh"

echo "构建完成! ISO 文件在 output/ 目录"
