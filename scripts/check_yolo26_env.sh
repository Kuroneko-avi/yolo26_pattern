#!/usr/bin/env bash
set -euo pipefail

CONDA_ROOT="${CONDA_ROOT:-/home/ywag/miniconda3}"
ENV_PY="${CONDA_ROOT}/envs/yolo26/bin/python"
ENV_YOLO="${CONDA_ROOT}/envs/yolo26/bin/yolo"
DATA_YAML="/home/ywag/yolo26_pattern/export_sentry_1_240_yolo/meta/dataset.local.yaml"

echo "[system]"
uname -a
command -v nvidia-smi >/dev/null && nvidia-smi || true
command -v docker >/dev/null && docker --version || true

echo "[python]"
"${ENV_PY}" - <<'PY'
import sys
import torch
print("python:", sys.version)
print("torch:", torch.__version__)
print("cuda built:", torch.version.cuda)
print("cuda available:", torch.cuda.is_available())
print("cuda devices:", torch.cuda.device_count())
for i in range(torch.cuda.device_count()):
    print(f"device {i}:", torch.cuda.get_device_name(i))
PY

echo "[ultralytics]"
"${ENV_YOLO}" checks || true

echo "[dataset]"
test -f "${DATA_YAML}"
find /home/ywag/yolo26_pattern/export_sentry_1_240_yolo/images/train -type f | wc -l
find /home/ywag/yolo26_pattern/export_sentry_1_240_yolo/images/val -type f | wc -l
find /home/ywag/yolo26_pattern/export_sentry_1_240_yolo/labels/train -type f | wc -l
find /home/ywag/yolo26_pattern/export_sentry_1_240_yolo/labels/val -type f | wc -l
