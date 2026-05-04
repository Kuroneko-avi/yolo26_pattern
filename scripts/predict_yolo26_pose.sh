#!/usr/bin/env bash
set -euo pipefail

CONDA_ROOT="${CONDA_ROOT:-/home/ywag/miniconda3}"
YOLO="${CONDA_ROOT}/envs/yolo26/bin/yolo"
MODEL="${MODEL:-/home/ywag/yolo26_pattern/runs/yolo26_pose_train/weights/best.pt}"
SOURCE="${1:-/home/ywag/yolo26_pattern/export_sentry_1_240_yolo/images/val}"

"${YOLO}" pose predict \
  model="${MODEL}" \
  source="${SOURCE}" \
  imgsz=640 \
  conf=0.25 \
  save=True \
  project=/home/ywag/yolo26_pattern/runs \
  name=yolo26_pose_predict \
  exist_ok=True
