#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONDA_ROOT="${CONDA_ROOT:-/home/kellen/anaconda3}"
YOLO="${CONDA_ROOT}/envs/yolo26/bin/yolo"
MODEL="${MODEL:-${REPO_ROOT}/runs/yolo26_pose_train/weights/best.pt}"
SOURCE="${SOURCE:-${1:-${REPO_ROOT}/export_5pt_pose_yolo/images/val}}"
PROJECT="${PROJECT:-${REPO_ROOT}/runs}"
NAME="${NAME:-yolo26_pose_predict}"
IMGSZ="${IMGSZ:-640}"
CONF="${CONF:-0.25}"

"${YOLO}" pose predict \
  model="${MODEL}" \
  source="${SOURCE}" \
  imgsz="${IMGSZ}" \
  conf="${CONF}" \
  save=True \
  project="${PROJECT}" \
  name="${NAME}" \
  exist_ok=True \
  "$@"
