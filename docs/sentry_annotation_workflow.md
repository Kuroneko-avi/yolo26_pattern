# Sentry 标注行动指南与 CVAT 工作流

本文给参与 `sentry` 图案标注的同事和负责人使用。目标是通过 CVAT 完成多人协作标注，由负责人统一验收，并在训练机器上训练 YOLO26-Pose 模型，输出 `.pt` 权重。

## 0. 一页速查

### 给标注同事

只需要做这些事：

1. 安装并登录 Tailscale。
2. 确认能访问负责人主机：

```powershell
tailscale ping 100.127.219.54
```

3. 用 Chrome 或 Edge 打开：

```text
http://100.127.219.54:8080
```

4. 登录负责人分配的 CVAT 账号。
5. 进入分配给自己的 Job。
6. 只标注完整可见的 `sentry`，每个目标标 1 个 bbox 和 8 个固定顺序 keypoints。
7. 遮挡、出画、不完整、点位不确定的目标一律不标。
8. 完成后通知负责人验收。

标注同事不需要安装 Conda、YOLO、CUDA、Docker、WSL2 或 CVAT。

### 给管理员/负责人

日常只需要维护这几件事：

1. 确认 CVAT 服务正常：

```bash
cd ~/cvat
sudo docker compose ps
curl -I http://100.127.219.54:8080
```

2. 确认 CVAT Host 配置：

```text
/home/kellen/cvat/.env
CVAT_HOST=100.127.219.54
```

3. 给同事创建账号并分配 Job。
4. 提供 `sentry` 8 点顺序参考图。
5. 抽检并验收标注。
6. 从 CVAT 导出 `Ultralytics YOLO Pose` 数据集。
7. 在本仓库训练并归档 `.pt` 权重。

不要把 CVAT 管理员密码、同事密码、Tailscale 邀请链接或 API token 写进 Git 文档。账号密码应通过线下或可信即时通讯单独发送。

## 1. 推荐工作模式

采用集中式 CVAT 服务：

```text
负责人训练主机运行 CVAT Docker 服务
同事 Windows 电脑通过 Tailscale + 浏览器访问 CVAT
图片和标注数据保存在负责人主机
负责人分配任务、验收、导出 YOLO-Pose 数据集
负责人在本机 Conda 环境训练并输出 best.pt
```

同事不需要安装 Conda、YOLO、CUDA、Docker 或 WSL2。只需要加入同一个 Tailscale 网络，并使用浏览器访问 CVAT。

## 2. 网络访问方式

当前统一使用 Tailscale IP 访问：

```text
http://100.127.219.54:8080
```

负责人主机当前 CVAT 配置：

```text
/home/kellen/cvat/.env
CVAT_HOST=100.127.219.54
```

同事访问前需要确认：

- 已安装并登录 Tailscale。
- 已加入和负责人主机相同的 Tailscale 网络。
- 浏览器访问 `http://100.127.219.54:8080`。
- 不要访问自己的 `localhost:8080`。

如果同事无法访问，先在同事电脑上测试：

```bash
tailscale ping 100.127.219.54
```

如果 `tailscale ping` 不通，说明不是 CVAT 问题，优先检查 Tailscale 登录、设备授权和网络 ACL。

如果 `tailscale ping` 通但浏览器打不开，负责人检查：

- 负责人主机是否开机。
- CVAT Docker 容器是否运行。
- Tailscale IP 是否仍为 `100.127.219.54`。
- `/home/kellen/cvat/.env` 里的 `CVAT_HOST` 是否正确。
- `8080` 端口是否正在监听。

负责人本机检查命令：

```bash
cd ~/cvat
sudo docker compose ps
curl -I http://100.127.219.54:8080
curl -sS http://100.127.219.54:8080/api/server/about
```

注意：当前 CVAT Host 已切到 Tailscale IP，局域网地址 `http://10.148.201.42:8080` 返回 `404` 属于正常现象。

## 3. 同事首次接入 Tailscale

同事使用 Windows 10/11 时，推荐只安装 Tailscale 客户端和浏览器，不需要安装 CVAT。

### 3.1 安装 Tailscale

从 Tailscale 官方网站下载 Windows 客户端：

```text
https://tailscale.com/download/windows
```

安装后登录负责人指定的 Tailscale 账号或加入负责人提供的 Tailnet。

### 3.2 确认设备已加入网络

在 Windows 的 Tailscale 托盘图标里确认状态为 Connected。

也可以打开 PowerShell 执行：

```powershell
tailscale status
tailscale ping 100.127.219.54
```

只要 `tailscale ping 100.127.219.54` 能通，就说明同事电脑已经能通过 Tailscale 到达负责人主机。

### 3.3 打开 CVAT

使用 Chrome 或 Edge 访问：

```text
http://100.127.219.54:8080
```

登录负责人分配的 CVAT 账号，然后进入分配给自己的 Job。

### 3.4 常见问题

如果浏览器打不开：

- 先确认 Tailscale 是 Connected。
- 再执行 `tailscale ping 100.127.219.54`。
- 如果 ping 不通，联系负责人检查 Tailscale 设备授权。
- 如果 ping 通但网页打不开，联系负责人检查 CVAT 服务。

## 4. Windows 10/11 本地部署 CVAT 教程

大多数情况下，同事不需要本地部署 CVAT。只有在个人离线练习、临时自建环境或负责人主机不可访问时，才需要在 Windows 上部署。

推荐路线：

```text
Windows 10/11
-> WSL2
-> Docker Desktop
-> CVAT Docker 容器
-> 浏览器访问 localhost:8080
```

### 4.1 安装 WSL2

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

### 4.2 安装 Docker Desktop

安装 Docker Desktop for Windows，并确认：

- Settings -> General -> Use the WSL 2 based engine 已开启。
- Settings -> Resources -> WSL Integration 中启用 Ubuntu。
- Docker Desktop 正常启动。

在 WSL Ubuntu 里检查：

```bash
docker --version
docker compose version
```

### 4.3 安装 Git

在 WSL Ubuntu 里执行：

```bash
sudo apt update
sudo apt install -y git
```

### 4.4 下载 CVAT

在 WSL Ubuntu 里执行：

```bash
git clone https://github.com/cvat-ai/cvat.git
cd cvat
```

### 4.5 启动 CVAT

在 `cvat` 目录执行：

```bash
docker compose up -d
```

首次启动会下载镜像，耗时较长。启动后访问：

```text
http://localhost:8080
```

### 4.6 创建管理员账号

在 `cvat` 目录执行：

```bash
docker exec -it cvat_server bash -ic 'python3 ~/manage.py createsuperuser'
```

按提示创建用户名、邮箱和密码。

### 4.7 停止和重启

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

## 5. Sentry 标注目标

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

## 6. Sentry 标注规则

### 6.1 必须标注

只标注满足以下条件的目标：

- 图案完整出现在画面内。
- 8 个关键点都能明确看到。
- 点位顺序可以无歧义判断。
- bbox 可以完整框住整个 `sentry` 图案。

### 6.2 不要标注

以下目标一律不标注：

- 被遮挡。
- 有一部分出画。
- 图案太糊，8 个点不能稳定判断。
- 反光、过曝、阴影导致点位不可确认。
- 只能看到局部图案。
- 不确定是不是 `sentry`。

### 6.3 bbox 规则

- bbox 框完整图案外接矩形。
- 不要只框可见局部。
- 不要把背景、其他图案、遮挡物框进去。
- 同一张图有多个完整 `sentry` 时，每个目标分别标注。

### 6.4 8 个关键点规则

- 沿用当前项目已有 8 点顺序。
- 同一个几何特征点永远使用同一个点编号。
- 不能因为图案旋转、倾斜、远近变化而改变顺序。
- 如果无法判断某个点，不要猜；这个目标直接不标。

负责人应提供一张 `sentry_8points_reference.png`，标清：

```text
p0, p1, p2, p3, p4, p5, p6, p7
```

所有同事必须按这张参考图标注。

## 7. 管理员 CVAT 运维

CVAT 源码和 Docker Compose 目录：

```text
/home/kellen/cvat
```

启动或恢复服务：

```bash
cd ~/cvat
sudo docker compose up -d
```

查看容器状态：

```bash
cd ~/cvat
sudo docker compose ps
```

查看日志：

```bash
cd ~/cvat
sudo docker compose logs -f
```

健康检查：

```bash
sudo docker exec -t cvat_server python manage.py health_check
```

如果普通用户执行 `docker compose` 报权限错误：

```text
permission denied while trying to connect to the Docker daemon socket
```

优先使用：

```bash
cd ~/cvat
sudo docker compose up -d
```

长期解决方式：

```bash
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
```

然后注销重新登录，或执行：

```bash
newgrp docker
```

检查 Tailscale IP：

```bash
tailscale ip -4
```

如果 Tailscale IP 改变，需要更新：

```text
/home/kellen/cvat/.env
CVAT_HOST=<新的 Tailscale IP>
```

然后重启：

```bash
cd ~/cvat
sudo docker compose up -d
```

## 8. 负责人 CVAT 项目工作流

### 8.1 创建项目

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

### 8.2 上传图片

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

### 8.3 创建账号和分配任务

负责人给每个同事创建账号，并分配 Job。

账号规则：

- 每个同事使用独立账号，不共用管理员账号。
- 用户名建议使用姓名拼音或常用英文名，避免后续追责困难。
- 密码不要写入本仓库文档。
- 新同事先分配小批量 Job，通过验收后再扩大任务量。

分配原则：

- 一个 Job 只给一个人负责。
- 不要多人同时改同一个 Job。
- 每个 Job 附带同一份标注说明和 8 点参考图。
- 标注员只按规范标注，不自行修改点位定义。
- 负责人记录每个 Job 的标注人、图片范围、完成时间和验收状态。

### 8.4 验收

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

验收通过后，负责人再把 Job 标记为 accepted 或记录为可导出状态。未验收数据不要进入训练集。

## 9. 标注员工作流

同事只需要浏览器：

```text
Chrome / Edge -> http://100.127.219.54:8080 -> 登录 -> 进入分配的 Job
```

每张图处理顺序：

1. 判断是否存在完整 `sentry`。
2. 不完整目标直接跳过。
3. 对每个完整目标画 Skeleton/bbox。
4. 按 `p0 -> p7` 顺序放置关键点。
5. 完成后逐张快速复查点顺序。
6. 完成整个 Job 后通知负责人验收。

提交前自检：

- 是否误标遮挡/出画目标。
- 是否漏标完整目标。
- 点顺序是否反了、错位了。
- bbox 是否明显过大或过小。

不要做的事：

- 不要修改项目 Label 或 Skeleton 配置。
- 不要自行改 8 个点的定义。
- 不要把不确定目标勉强标进去。
- 不要多人共用同一个账号标注。

## 10. 数据导出

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

## 11. 自动标注流程

自动标注只用于提高效率，不作为最终结果。

### 11.1 第一阶段：人工标注

先人工标注一批高质量数据：

```text
至少 500 - 1000 张完整 sentry 图
```

训练出更稳定的 `best.pt`。

### 11.2 第二阶段：模型预标注

负责人用当前模型对新图片预标注：

```bash
MODEL=runs/yolo26_pose_train/weights/best.pt \
SOURCE=/path/to/new/images \
bash scripts/predict_yolo26_pose.sh
```

后续可以扩展脚本，输出可导入 CVAT 的标注格式。

### 11.3 第三阶段：人工修正

标注员只做三件事：

1. 删除不完整目标的预测。
2. 修正错误 bbox。
3. 修正错误 keypoints。

自动标注结果必须人工验收后才能进入训练集。

## 12. 训练交付流程

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

## 13. 7 类图案扩展原则

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

## 14. 官方参考

- CVAT Windows/WSL2/Docker 安装：https://docs.cvat.ai/docs/administration/basics/installation/
- CVAT Skeleton 标注：https://docs.cvat.ai/docs/annotation/manual-annotation/shapes/skeletons/
- CVAT Ultralytics YOLO Pose 格式：https://docs.cvat.ai/docs/dataset_management/formats/format-yolo-ultralytics/
- CVAT 自动标注：https://docs.cvat.ai/docs/annotation/auto-annotation/automatic-annotation/
