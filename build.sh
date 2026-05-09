#!/bin/bash
set -e
set -o pipefail

mkdir -p armbian
mkdir -p output

VERSION_TYPE="${VERSION_TYPE:-standard}"
echo "构建版本: $VERSION_TYPE"

# 根据版本选择文件名模式（用通配符匹配最新镜像）
case "$VERSION_TYPE" in
  debian13_minimal)
    FILE_PATTERN="Armbian_*_trixie_*_minimal.img.xz"
    ;;
  ubuntu24_minimal)
    FILE_PATTERN="Armbian_*_noble_*_minimal.img.xz"
    ;;
  ubuntu26_minimal)
    FILE_PATTERN="Armbian_*_resolute_*_minimal.img.xz"
    ;;
  *)
    FILE_PATTERN="Armbian_*_noble_*_minimal.img.xz"
    ;;
esac

BASE_URL="https://mirrors.nju.edu.cn/armbian-releases/uefi-x86/archive/"

# 获取下载链接（保证 URL 拼接正确）
echo "正在获取下载链接..."
DOWNLOAD_URL=$(curl -s "$BASE_URL" | \
    grep -oP "/armbian-releases/uefi-x86/archive/[^\"]*$(basename $FILE_PATTERN | sed 's/\*/.*/g')" | head -n1)

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "错误：未找到匹配文件 $FILE_PATTERN"
  exit 1
fi

DOWNLOAD_URL="https://mirrors.nju.edu.cn$DOWNLOAD_URL"
FILE_NAME=$(basename "$DOWNLOAD_URL")
OUTPUT_PATH="armbian/armbian.img.xz"

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"

# 下载文件
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

echo "下载成功!"
file "$OUTPUT_PATH"

# 解压
echo "正在解压为: armbian.img ..."
xz -d -T0 "$OUTPUT_PATH"  # -T0 使用所有 CPU 线程

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
