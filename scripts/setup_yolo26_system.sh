#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash scripts/setup_yolo26_system.sh" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-ywag}"
KERNEL_RELEASE="$(uname -r)"

echo "[1/7] Updating apt metadata and packages"
apt update
apt upgrade -y

echo "[2/7] Installing base development tools"
apt install -y \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  dkms \
  git \
  gnupg \
  htop \
  lsb-release \
  net-tools \
  tmux \
  wget \
  "linux-headers-${KERNEL_RELEASE}"

echo "[3/7] Installing NVIDIA driver module for current kernel: ${KERNEL_RELEASE}"
apt install -y \
  nvidia-driver-580 \
  "linux-modules-nvidia-580-${KERNEL_RELEASE}"

echo "[4/7] Loading NVIDIA kernel module"
modprobe nvidia || true
nvidia-smi || true

echo "[5/7] Installing Docker from Ubuntu repositories"
apt install -y docker.io containerd runc
systemctl enable --now docker
usermod -aG docker "${TARGET_USER}"

echo "[6/7] Installing NVIDIA Container Toolkit"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | gpg --dearmor -o /etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

echo "[7/7] Final checks"
uname -r
nvidia-smi || true
docker --version || true
docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu22.04 nvidia-smi || true

echo "Done. Log out and log back in, or run 'newgrp docker', before using docker without sudo."
