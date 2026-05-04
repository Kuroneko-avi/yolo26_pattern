# Sentry 标注行动指南与 CVAT 工作流

本文给参与 `sentry` 图案标注的同事和负责人使用。目标是通过 CVAT 完成多人协作标注，由负责人统一验收，并在训练机器上训练 YOLO26-Pose 模型，输出 `.pt` 权重。

## 1. 推荐工作模式

采用集中式 CVAT 服务：

```text
负责人训练主机运行 CVAT Docker 服务
同事 Windows 电脑通过浏览器访问 CVAT
图片和标注数据保存在负责人主机
负责人分配任务、验收、导出 YOLO-Pose 数据集
负责人在本机 Conda 环境训练并输出 best.pt
```

同事不需要安装 Conda、YOLO、CUDA、Docker 或 WSL2。只需要和负责人主机处于同一局域网，并使用浏览器访问 CVAT。

## 2. 网络访问方式

负责人主机：

```text
http://localhost:8080
```

同事电脑：

```text
http://负责人主机局域网IP:8080
```

查看负责人主机局域网 IP：

```bash
ip addr
```

如果同事无法访问，优先检查：

- 负责人主机是否开机。
- CVAT Docker 容器是否运行。
- 同事和负责人是否在同一局域网。
- 防火墙是否放行 `8080` 端口。
- 浏览器地址是否使用负责人主机 IP，而不是同事自己的 `localhost`。

## 3. Windows 10/11 本地部署 CVAT 教程

大多数情况下，同事不需要本地部署 CVAT。只有在个人离线练习、临时自建环境或负责人主机不可访问时，才需要在 Windows 上部署。

推荐路线：

```text
Windows 10/11
-> WSL2
-> Docker Desktop
-> CVAT Docker 容器
-> 浏览器访问 localhost:8080
```

### 3.1 安装 WSL2

在 Windows PowerShell 管理员模式执行：

```powershell
wsl --install
```

安装完成后重启电脑。建议使用 Ubuntu 22.04 或更新版本。

检查 WSL：

```powershell
wsl -l -v
```

确认 Ubuntu 使用的是 WSL2。

### 3.2 安装 Docker Desktop

安装 Docker Desktop for Windows，并确认：

- Settings -> General -> Use the WSL 2 based engine 已开启。
- Settings -> Resources -> WSL Integration 中启用 Ubuntu。
- Docker Desktop 正常启动。

在 WSL Ubuntu 里检查：

```bash
docker --version
docker compose version
```

### 3.3 安装 Git

在 WSL Ubuntu 里执行：

```bash
sudo apt update
sudo apt install -y git
```

### 3.4 下载 CVAT

在 WSL Ubuntu 里执行：

```bash
git clone https://github.com/cvat-ai/cvat.git
cd cvat
```

### 3.5 启动 CVAT

在 `cvat` 目录执行：

```bash
docker compose up -d
```

首次启动会下载镜像，耗时较长。启动后访问：

```text
http://localhost:8080
```

### 3.6 创建管理员账号

在 `cvat` 目录执行：

```bash
docker exec -it cvat_server bash -ic 'python3 ~/manage.py createsuperuser'
```

按提示创建用户名、邮箱和密码。

### 3.7 停止和重启

停止：

```bash
docker compose down
```

重启：

```bash
docker compose up -d
```

查看容器：

```bash
docker ps
```

## 4. Sentry 标注目标

类别固定为：

```text
sentry
```

每个完整目标需要标注：

```text
1 个 bbox + 8 个固定顺序 keypoints
```

训练目标：

```text
只识别完整可见的 sentry 图案，并输出固定顺序的 8 个关键点像素坐标。
```

不完整目标不要标注。

## 5. Sentry 标注规则

### 5.1 必须标注

只标注满足以下条件的目标：

- 图案完整出现在画面内。
- 8 个关键点都能明确看到。
- 点位顺序可以无歧义判断。
- bbox 可以完整框住整个 `sentry` 图案。

### 5.2 不要标注

以下目标一律不标注：

- 被遮挡。
- 有一部分出画。
- 图案太糊，8 个点不能稳定判断。
- 反光、过曝、阴影导致点位不可确认。
- 只能看到局部图案。
- 不确定是不是 `sentry`。

### 5.3 bbox 规则

- bbox 框完整图案外接矩形。
- 不要只框可见局部。
- 不要把背景、其他图案、遮挡物框进去。
- 同一张图有多个完整 `sentry` 时，每个目标分别标注。

### 5.4 8 个关键点规则

- 沿用当前项目已有 8 点顺序。
- 同一个几何特征点永远使用同一个点编号。
- 不能因为图案旋转、倾斜、远近变化而改变顺序。
- 如果无法判断某个点，不要猜；这个目标直接不标。

负责人应提供一张 `sentry_8points_reference.png`，标清：

```text
p0, p1, p2, p3, p4, p5, p6, p7
```

所有同事必须按这张参考图标注。

## 6. 负责人 CVAT 工作流

### 6.1 创建项目

项目名建议：

```text
sentry_pose_v001
```

标签配置：

```text
label: sentry
type: skeleton
points: p0, p1, p2, p3, p4, p5, p6, p7
```

建议在 Skeleton 里连接少量辅助边，让标注员能看清点位顺序。训练最终只关心点坐标。

### 6.2 上传图片

按批次上传图片，例如：

```text
batch_001
batch_002
batch_003
```

每个 Task 建议控制在：

```text
100 - 300 张图片
```

### 6.3 创建账号和分配任务

负责人给每个同事创建账号，并分配 Job。

分配原则：

- 一个 Job 只给一个人负责。
- 不要多人同时改同一个 Job。
- 每个 Job 附带同一份标注说明和 8 点参考图。
- 标注员只按规范标注，不自行修改点位定义。

### 6.4 验收

每个 Job 抽检比例：

```text
至少 20%
```

新同事或首批数据：

```text
抽检 50% - 100%
```

退回标准：

- 任意系统性点位顺序错误。
- 大量标注了不完整目标。
- bbox 风格明显不统一。
- 漏标率高。
- 关键点放在非固定几何特征上。

## 7. 标注员工作流

同事只需要浏览器：

```text
Chrome / Edge -> http://负责人主机IP:8080 -> 登录 -> 进入分配的 Job
```

每张图处理顺序：

1. 判断是否存在完整 `sentry`。
2. 不完整目标直接跳过。
3. 对每个完整目标画 Skeleton/bbox。
4. 按 `p0 -> p7` 顺序放置关键点。
5. 完成后逐张快速复查点顺序。

提交前自检：

- 是否误标遮挡/出画目标。
- 是否漏标完整目标。
- 点顺序是否反了、错位了。
- bbox 是否明显过大或过小。

## 8. 数据导出

负责人统一从 CVAT 导出：

```text
Ultralytics YOLO Pose
```

导出后应包含：

```text
data.yaml
images/
labels/
```

导出数据集由负责人合并到训练机项目目录，再训练。

## 9. 自动标注流程

自动标注只用于提高效率，不作为最终结果。

### 9.1 第一阶段：人工标注

先人工标注一批高质量数据：

```text
至少 500 - 1000 张完整 sentry 图
```

训练出更稳定的 `best.pt`。

### 9.2 第二阶段：模型预标注

负责人用当前模型对新图片预标注：

```bash
MODEL=runs/yolo26_pose_train/weights/best.pt \
SOURCE=/path/to/new/images \
bash scripts/predict_yolo26_pose.sh
```

后续可以扩展脚本，输出可导入 CVAT 的标注格式。

### 9.3 第三阶段：人工修正

标注员只做三件事：

1. 删除不完整目标的预测。
2. 修正错误 bbox。
3. 修正错误 keypoints。

自动标注结果必须人工验收后才能进入训练集。

## 10. 训练交付流程

负责人从 CVAT 导出 YOLO-Pose 数据集后，在训练机器执行：

```bash
bash scripts/train_yolo26_pose.sh
```

训练完成后保留：

```text
runs/yolo26_pose_train/weights/best.pt
runs/yolo26_pose_train/results.csv
runs/yolo26_pose_train/results.png
runs/yolo26_pose_predict/
```

每次模型版本命名：

```text
sentry_pose_v001.pt
sentry_pose_v002.pt
sentry_pose_v003.pt
```

版本记录至少包含：

```text
数据集版本：
图片数量：
目标数量：
训练命令：
权重路径：
主要失败样本：
```

## 11. 7 类图案扩展原则

当前先只做 `sentry`。

后续每增加一个图案，先单独定义：

- 类别名。
- 是否也输出 8 个点。
- 8 个点各自对应什么几何特征。
- 是否只保留完整目标。
- PnP 使用的 3D 点坐标模板。

如果未来 7 类都能稳定输出 8 点，可以合并成一个多类 YOLO-Pose 模型：

```text
class_id + bbox + 8 keypoints
```

PnP 端按 `class_id` 选择对应的 3D 点模板。

## 12. 官方参考

- CVAT Windows/WSL2/Docker 安装：https://docs.cvat.ai/docs/administration/basics/installation/
- CVAT Skeleton 标注：https://docs.cvat.ai/docs/annotation/manual-annotation/shapes/skeletons/
- CVAT Ultralytics YOLO Pose 格式：https://docs.cvat.ai/docs/dataset_management/formats/format-yolo-ultralytics/
- CVAT 自动标注：https://docs.cvat.ai/docs/annotation/auto-annotation/automatic-annotation/
