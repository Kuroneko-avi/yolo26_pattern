# yolo26_pattern

`yolo26_pattern` 是一个 YOLO26-Pose 训练仓库，当前目标是训练 `sentry` 图案识别与 8 个固定顺序关键点定位模型，并输出 `.pt` 权重供后续相机/PnP 程序使用。

## 项目目标

- 输入：标注好的 YOLO-Pose 数据集。
- 输出：YOLO26-Pose `.pt` 权重。
- 当前类别：`sentry`。
- 当前标注格式：每个完整目标 1 个 bbox + 8 个 keypoints。
- 当前训练策略：只训练完整可见图案；遮挡、出画、不完整、点位不确定的目标不标注。

本仓库只负责训练与验收，不负责最终相机应用、PnP 解算或部署系统。

## 目录结构

```text
.
├── AGENTS.md
├── README.md
├── docs/
│   └── sentry_annotation_workflow.md
├── export_sentry_1_240_yolo/
│   ├── images/
│   ├── labels/
│   └── meta/
│       └── dataset.local.yaml
├── scripts/
│   ├── check_yolo26_env.sh
│   ├── predict_yolo26_pose.sh
│   ├── setup_yolo26_system.sh
│   └── train_yolo26_pose.sh
├── environment-yolo26.yaml
├── requirements-yolo26.txt
└── conda-yolo26-explicit.txt
```

## 当前环境

主训练环境是 Conda：

```text
/home/kellen/anaconda3/envs/yolo26
```

训练默认使用 GPU `0`，也就是 RTX 4080。Docker 已安装，但 Docker GPU runtime 不是当前训练主流程。

检查环境：

```bash
/home/kellen/anaconda3/envs/yolo26/bin/yolo checks
```

## 数据集配置

本机数据集配置：

```text
export_sentry_1_240_yolo/meta/dataset.local.yaml
```

当前配置要点：

```yaml
nc: 1
names:
  0: sentry
kpt_shape: [8, 3]
```

## 训练

默认训练：

```bash
bash scripts/train_yolo26_pose.sh
```

脚本默认参数：

```text
MODEL=/home/kellen/yolo26_pattern/yolo26n-pose.pt
EPOCHS=100
IMGSZ=640
BATCH=96
DEVICE=0
WORKERS=8
CACHE=ram
```

保守 batch 训练：

```bash
BATCH=64 bash scripts/train_yolo26_pose.sh
```

自定义运行名：

```bash
NAME=sentry_pose_v002 EPOCHS=200 bash scripts/train_yolo26_pose.sh
```

## 预测验收

使用训练好的 `best.pt` 预测验证集：

```bash
MODEL=runs/yolo26_pose_train/weights/best.pt bash scripts/predict_yolo26_pose.sh
```

预测结果默认保存到：

```text
runs/yolo26_pose_predict/
```

验收重点：

- bbox 是否框住完整 `sentry`。
- 8 个 keypoints 是否都在正确位置。
- keypoint 顺序是否稳定。
- 是否错误输出了遮挡、出画或不完整目标。

## 权重输出

训练完成后主要使用：

```text
runs/yolo26_pose_train/weights/best.pt
```

建议按版本另存：

```text
sentry_pose_v001.pt
sentry_pose_v002.pt
sentry_pose_v003.pt
```

`.pt` 权重不提交到 Git。

## 标注工作流

同事标注、负责人验收、本机训练的详细流程见：

```text
docs/sentry_annotation_workflow.md
```

推荐方式：

```text
本机部署 CVAT -> 同事通过 Tailscale 浏览器访问 -> 同事标注 -> 负责人验收 -> 导出 YOLO-Pose -> 本机训练 -> 输出 best.pt
```

当前 CVAT 访问地址：

```text
http://100.90.129.85:8080
```

CVAT 运行在 `/home/kellen/cvat`，当前 `.env` 使用：

```text
CVAT_HOST=100.90.129.85
```

管理员常用命令：

```bash
cd ~/cvat
sudo docker compose ps
sudo docker compose up -d
sudo docker compose logs -f
```

## 环境复现

已导出三份环境文件：

```text
environment-yolo26.yaml
requirements-yolo26.txt
conda-yolo26-explicit.txt
```

常用恢复方式：

```bash
/home/kellen/anaconda3/bin/conda env create -f environment-yolo26.yaml
```

更严格的 Conda 显式包列表恢复可参考：

```bash
/home/kellen/anaconda3/bin/conda create --name yolo26 --file conda-yolo26-explicit.txt
```

## Git 说明

已忽略：

```text
runs/
*.pt
*.cache
__pycache__/
.ipynb_checkpoints/
```

不要提交训练产物、模型权重、cache 文件。应提交文档、脚本、环境清单和数据集配置。
