#!/bin/bash
set -e

mkdir -p armbian

VERSION_TYPE="${VERSION_TYPE:-standard}"
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

OUTPUT_PATH="armbian/armbian.img.xz"

DOWNLOAD_URL=$(curl -s https://mirrors.nju.edu.cn/armbian-releases/uefi-x86/archive/ | \
               grep -oP "href=\"[^\"]*$FILE_NAME\"" | head -n1 | sed 's/href="//')
DOWNLOAD_URL="https://mirrors.nju.edu.cn$DOWNLOAD_URL"

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "错误：未找到文件 $FILE_NAME"
  exit 1
fi

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

echo "下载成功!"
file "$OUTPUT_PATH"
echo "正在解压为: armbian.img"
xz -d "$OUTPUT_PATH"

if [[ ! -f armbian/armbian.img ]]; then
  echo "错误：armbian.img 不存在，无法启动 Docker 构建"
  exit 1
fi

mkdir -p output
docker run --privileged --rm \
  -v $(pwd)/output:/output \
  -v $(pwd)/supportFiles:/supportFiles:ro \
  -v $(pwd)/armbian/armbian.img:/mnt/armbian.img \
  debian:buster bash -c "apt update && apt install -y xz-utils && /supportFiles/build.sh"
