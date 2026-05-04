# AGENTS.md

This file applies to the entire `yolo26_pattern` repository.

## Communication

- Internal reasoning and technical analysis should be performed in English.
- Final user-facing responses should be professional, concise Chinese.
- Keep common technical terms in English when clearer, for example YOLO-Pose, Conda, CVAT, keypoints, bbox, PnP, Docker.

## Project Scope

This repository is responsible for:

- Managing YOLO-Pose datasets for pattern detection and keypoint localization.
- Training YOLO26-Pose models in the local Conda environment.
- Validating predictions visually and with training metrics.
- Exporting `.pt` model weights for downstream camera/PnP applications.

This repository is not responsible for:

- Production camera application deployment.
- PnP solver implementation.
- Robot/control-system integration.
- Long-term CVAT server operations beyond documentation and data export/import workflow.

## Current Primary Task

- The active pattern class is `sentry`.
- The training target is one complete visible `sentry` pattern.
- Each valid target has one bbox and exactly 8 fixed-order keypoints.
- Occluded, cropped, incomplete, blurry, or ambiguous targets should not be annotated for the current training goal.
- Keypoint order must remain stable within the `sentry` class because downstream PnP depends on consistent 2D-to-3D point correspondence.

## Environment

- Prefer the existing Conda environment at `/home/ywag/miniconda3/envs/yolo26`.
- Use `/home/ywag/miniconda3/envs/yolo26/bin/yolo` for Ultralytics commands.
- Default training device is GPU `0`, the RTX 4080.
- Do not make Docker GPU runtime a blocker for normal training; Conda is the current primary training path.

## Common Commands

Check environment:

```bash
/home/ywag/miniconda3/envs/yolo26/bin/yolo checks
```

Train:

```bash
bash scripts/train_yolo26_pose.sh
```

Predict on validation images:

```bash
MODEL=runs/yolo26_pose_train/weights/best.pt bash scripts/predict_yolo26_pose.sh
```

Use a conservative batch if needed:

```bash
BATCH=64 bash scripts/train_yolo26_pose.sh
```

## Data And Git Hygiene

- Do not commit generated training runs, model weights, or dataset cache files.
- Keep `runs/`, `*.pt`, and `*.cache` ignored.
- Commit reproducibility files such as `environment-yolo26.yaml`, `requirements-yolo26.txt`, and `conda-yolo26-explicit.txt`.
- Prefer adding docs/scripts that make the annotation-train-validate workflow reproducible.

## Documentation Expectations

- Keep `README.md` focused on repository usage.
- Keep teammate annotation instructions in `docs/sentry_annotation_workflow.md`.
- If annotation policy changes, update the docs before training a new dataset version.
