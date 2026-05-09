#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONDA_ROOT="${CONDA_ROOT:-/home/kellen/anaconda3}"
YOLO="${CONDA_ROOT}/envs/yolo26/bin/yolo"
MODEL="${MODEL:-${REPO_ROOT}/runs/yolo26_pose_train/weights/best.pt}"
SOURCE="${1:-${REPO_ROOT}/export_sentry_1_240_yolo/images/val}"

"${YOLO}" pose predict \
  model="${MODEL}" \
  source="${SOURCE}" \
  imgsz=640 \
  conf=0.25 \
  save=True \
  project="${REPO_ROOT}/runs" \
  name=yolo26_pose_predict \
  exist_ok=True
