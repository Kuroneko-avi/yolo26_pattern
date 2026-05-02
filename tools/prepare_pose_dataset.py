import argparse
import json
import random
import shutil
from pathlib import Path


def numeric_key(path: Path):
    try:
        return int(path.stem)
    except ValueError:
        return path.stem


def find_image_path(images_dir: Path, stem: str) -> Path:
    candidates = [
        images_dir / "train" / f"{stem}.jpg",
        images_dir / "val" / f"{stem}.jpg",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"Image not found for {stem}")


def bbox_from_rectangle(points):
    xs = [pt[0] for pt in points]
    ys = [pt[1] for pt in points]
    return min(xs), min(ys), max(xs), max(ys)


def format_pose_line(rect_shape, point_shapes, image_width, image_height):
    x1, y1, x2, y2 = bbox_from_rectangle(rect_shape["points"])
    cx = ((x1 + x2) / 2.0) / image_width
    cy = ((y1 + y2) / 2.0) / image_height
    w = (x2 - x1) / image_width
    h = (y2 - y1) / image_height

    values = [0, cx, cy, w, h]
    for idx in range(1, 9):
        point = point_shapes[f"pt{idx}"]["points"][0]
        px = point[0] / image_width
        py = point[1] / image_height
        values.extend([px, py, 2])

    formatted = [str(values[0])]
    formatted.extend(f"{value:.6f}" for value in values[1:])
    return " ".join(formatted)


def collect_pose_lines(annotation_path: Path):
    data = json.loads(annotation_path.read_text(encoding="utf-8"))
    groups = {}
    for shape in data.get("shapes", []):
        groups.setdefault(shape.get("group_id"), []).append(shape)

    lines = []
    duplicate_groups = []
    for group_id, shapes in groups.items():
        rectangles = [
            shape
            for shape in shapes
            if shape.get("label") == "sentry" and shape.get("shape_type") == "rectangle"
        ]
        if not rectangles:
            continue

        points = {}
        for shape in shapes:
            if shape.get("shape_type") == "point" and shape.get("label", "").startswith("pt"):
                points[shape["label"]] = shape

        if not all(f"pt{idx}" in points for idx in range(1, 9)):
            continue

        if len(rectangles) > 1:
            duplicate_groups.append(group_id)

        lines.append(
            format_pose_line(
                rectangles[-1],
                points,
                data["imageWidth"],
                data["imageHeight"],
            )
        )

    return lines, duplicate_groups


def ensure_dirs(dataset_root: Path):
    for relative in [
        Path("images/train"),
        Path("images/val"),
        Path("labels/train"),
        Path("labels/val"),
        Path("meta"),
    ]:
        (dataset_root / relative).mkdir(parents=True, exist_ok=True)


def move_to_split(source_path: Path, target_path: Path):
    if source_path.resolve() == target_path.resolve():
        return
    target_path.parent.mkdir(parents=True, exist_ok=True)
    if target_path.exists():
        target_path.unlink()
    shutil.move(str(source_path), str(target_path))


def remove_if_exists(path: Path):
    if path.exists():
        path.unlink()


def write_yaml(dataset_root: Path):
    yaml_content = (
        f"path: {dataset_root.as_posix()}\n"
        "train: images/train\n"
        "val: images/val\n\n"
        "nc: 1\n"
        "names:\n"
        "  0: sentry\n\n"
        "kpt_shape: [8, 3]\n"
    )
    for relative in ["meta/dataset.yaml", "meta/sentry_pose.yaml"]:
        (dataset_root / relative).write_text(yaml_content, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", required=True)
    parser.add_argument("--train-ratio", type=float, default=0.8)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    dataset_root = Path(args.dataset_root).resolve()
    annotations_dir = dataset_root / "annotations_json"
    images_dir = dataset_root / "images"
    labels_dir = dataset_root / "labels"

    ensure_dirs(dataset_root)

    annotation_paths = sorted(annotations_dir.glob("*.json"), key=numeric_key)
    stems = [path.stem for path in annotation_paths]
    rng = random.Random(args.seed)
    shuffled_stems = stems[:]
    rng.shuffle(shuffled_stems)
    train_count = int(len(shuffled_stems) * args.train_ratio)
    train_stems = set(shuffled_stems[:train_count])

    duplicate_group_records = []
    train_images = 0
    val_images = 0
    train_objects = 0
    val_objects = 0

    for annotation_path in annotation_paths:
        stem = annotation_path.stem
        split = "train" if stem in train_stems else "val"

        image_source = find_image_path(images_dir, stem)
        image_target = images_dir / split / image_source.name
        move_to_split(image_source, image_target)

        pose_lines, duplicate_groups = collect_pose_lines(annotation_path)
        if duplicate_groups:
            duplicate_group_records.append(
                f"{annotation_path.name}: groups {duplicate_groups}"
            )

        target_label = labels_dir / split / f"{stem}.txt"
        target_label.write_text(
            ("\n".join(pose_lines) + ("\n" if pose_lines else "")),
            encoding="utf-8",
        )
        remove_if_exists(labels_dir / ("val" if split == "train" else "train") / f"{stem}.txt")

        if split == "train":
            train_images += 1
            train_objects += len(pose_lines)
        else:
            val_images += 1
            val_objects += len(pose_lines)

    write_yaml(dataset_root)

    print(f"train_images={train_images}")
    print(f"val_images={val_images}")
    print(f"train_objects={train_objects}")
    print(f"val_objects={val_objects}")
    print(f"duplicate_group_records={duplicate_group_records}")


if __name__ == "__main__":
    main()
