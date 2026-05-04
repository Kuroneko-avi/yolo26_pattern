#!/usr/bin/env bash
set -euo pipefail

CONDA_ROOT="${CONDA_ROOT:-/home/ywag/miniconda3}"
YOLO="${CONDA_ROOT}/envs/yolo26/bin/yolo"
DATA="/home/ywag/yolo26_pattern/export_sentry_1_240_yolo/meta/dataset.local.yaml"
PROJECT="${PROJECT:-/home/ywag/yolo26_pattern/runs}"
MODEL="${MODEL:-/home/ywag/yolo26_pattern/yolo26n-pose.pt}"
EPOCHS="${EPOCHS:-100}"
IMGSZ="${IMGSZ:-640}"
BATCH="${BATCH:-96}"
DEVICE="${DEVICE:-0}"
WORKERS="${WORKERS:-8}"
CACHE="${CACHE:-ram}"
NAME="${NAME:-yolo26_pose_train}"

"${YOLO}" pose train \
  model="${MODEL}" \
  data="${DATA}" \
  epochs="${EPOCHS}" \
  imgsz="${IMGSZ}" \
  batch="${BATCH}" \
  device="${DEVICE}" \
  workers="${WORKERS}" \
  cache="${CACHE}" \
  project="${PROJECT}" \
  name="${NAME}" \
  exist_ok=True
