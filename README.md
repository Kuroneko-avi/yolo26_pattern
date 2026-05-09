# yolo26_pattern

`yolo26_pattern` 是一个 YOLO26-Pose 训练仓库，用来管理本机 YOLO-Pose 数据集、训练模型、做可视化验收，并输出 `.pt` 权重给后续相机/PnP 或其他下游程序使用。

本仓库只负责数据集、训练、验证和权重导出；不负责生产相机程序、PnP 解算、机器人控制或部署系统。

## 当前状态

当前主数据集是 5 点 YOLO-Pose 数据集：

```text
export_5pt_pose_yolo/
```

数据集来源：

```text
/home/kellen/下载/job_72_dataset_2026_05_09_08_42_30_ultralytics yolo pose 1.0.zip
/home/kellen/下载/第一组WU_1.zip
/home/kellen/下载/第一组WU_2.zip
```

清洗结果：

```text
total_images=100
total_objects=192
background_images=4
train_images=81
train_objects=156
train_background_images=3
val_images=19
val_objects=36
val_background_images=1
```

其中 `job_72` 里的 `screenshot-95/96/97/98` 已确认是背景图，已保留为空 label 背景样本。

数据集配置：

```text
export_5pt_pose_yolo/meta/dataset.local.yaml
```

配置要点：

```yaml
nc: 1
names:
  0: 大符标注
kpt_shape: [5, 3]
```

重命名与来源追溯表：

```text
export_5pt_pose_yolo/meta/rename_map.csv
```

仓库中还保留历史 8 点 `sentry` 数据集：

```text
export_sentry_1_240_yolo/
```

## 目录结构

```text
.
├── AGENTS.md
├── README.md
├── docs/
│   └── sentry_annotation_workflow.md
├── export_5pt_pose_yolo/
│   ├── images/
│   ├── labels/
│   └── meta/
│       ├── dataset.local.yaml
│       ├── rename_map.csv
│       ├── summary.json
│       └── summary.txt
├── export_sentry_1_240_yolo/
├── scripts/
│   ├── check_yolo26_env.sh
│   ├── predict_yolo26_pose.sh
│   ├── setup_yolo26_system.sh
│   └── train_yolo26_pose.sh
├── environment-yolo26.yaml
├── requirements-yolo26.txt
└── conda-yolo26-explicit.txt
```

## 环境

主训练环境是 Conda：

```text
/home/kellen/anaconda3/envs/yolo26
```

Ultralytics 命令：

```text
/home/kellen/anaconda3/envs/yolo26/bin/yolo
```

默认使用 GPU `0`。

检查环境：

```bash
/home/kellen/anaconda3/envs/yolo26/bin/yolo checks
```

## 训练

默认训练脚本：

```bash
bash scripts/train_yolo26_pose.sh
```

脚本默认参数：

```text
DATA=export_5pt_pose_yolo/meta/dataset.local.yaml
MODEL=yolo26n-pose.pt
EPOCHS=100
PATIENCE=100
IMGSZ=640
BATCH=96
DEVICE=0
WORKERS=8
CACHE=ram
NAME=yolo26_pose_train
```

继续使用已有 5 点权重做长轮次训练：

```bash
DATA=/home/kellen/yolo26_pattern/export_5pt_pose_yolo/meta/dataset.local.yaml \
MODEL=/home/kellen/yolo26_pattern/runs/export_5pt_pose_long_800e_p200/weights/best.pt \
EPOCHS=800 \
PATIENCE=200 \
BATCH=64 \
NAME=export_5pt_pose_long_800e_p200 \
bash scripts/train_yolo26_pose.sh
```

脚本支持继续透传 Ultralytics 原生参数，例如：

```bash
EPOCHS=300 PATIENCE=0 BATCH=64 bash scripts/train_yolo26_pose.sh cos_lr=True
```

## 当前最佳 5 点模型

最新长轮次训练：

```text
runs/export_5pt_pose_long_800e_p200/
```

训练配置：

```text
epochs=800
patience=200
实际早停=205 epochs
best epoch=5
```

权重：

```text
runs/export_5pt_pose_long_800e_p200/weights/best.pt
```

最终验证结果：

```text
Box(P,R,mAP50,mAP50-95)=0.917,0.972,0.985,0.931
Pose(P,R,mAP50,mAP50-95)=0.917,0.972,0.985,0.985
```

## 预测验收

默认预测当前 5 点 val：

```bash
MODEL=runs/export_5pt_pose_long_800e_p200/weights/best.pt \
NAME=export_5pt_pose_long_800e_p200_predict \
bash scripts/predict_yolo26_pose.sh
```

指定 source：

```bash
MODEL=runs/export_5pt_pose_long_800e_p200/weights/best.pt \
SOURCE=/path/to/images \
NAME=my_predict \
bash scripts/predict_yolo26_pose.sh
```

当前预测输出：

```text
runs/export_5pt_pose_long_800e_p200_predict/
```

验收重点：

- bbox 是否框住目标。
- 5 个 keypoints 是否都在正确位置。
- 背景图是否不输出误检。
- 如果发现漏标，先修 label，再重新清洗/训练；不要把应标目标当背景样本训练。

## Git 说明

已忽略：

```text
runs/
*.pt
*.cache
__pycache__/
.ipynb_checkpoints/
```

不要提交训练产物、模型权重、cache 文件。应提交文档、脚本、环境清单、数据集配置和需要版本化的数据集文件。
