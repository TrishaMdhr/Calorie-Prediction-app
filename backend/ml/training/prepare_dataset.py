"""
Prepare the Food-101 dataset for training.

Usage (PowerShell):
    python ml/training/prepare_dataset.py --food101 "C:\\path\\to\\food-101"

This reads meta/train.txt and meta/test.txt (provided by Food-101) and copies
the images into:
    <food101>/train/<class>/image.jpg
    <food101>/validation/<class>/image.jpg

After running, set your env vars and train:
    $env:FOOD101_TRAIN_DIR = "C:\\path\\to\\food-101\\train"
    $env:FOOD101_VAL_DIR   = "C:\\path\\to\\food-101\\validation"
    python ml/training/train_cnn.py
"""

import argparse
import shutil
from pathlib import Path


def prepare(food101_root: Path):
    images_dir = food101_root / "images"
    meta_dir   = food101_root / "meta"

    if not images_dir.is_dir():
        raise FileNotFoundError(f"images/ folder not found in {food101_root}")
    if not (meta_dir / "train.txt").is_file():
        raise FileNotFoundError(f"meta/train.txt not found in {food101_root}")

    for split, txt_file in [("train", "train.txt"), ("validation", "test.txt")]:
        split_dir = food101_root / split
        txt_path  = meta_dir / txt_file
        entries   = txt_path.read_text().strip().splitlines()

        print(f"\n[{split}] Copying {len(entries)} images...")
        for i, entry in enumerate(entries, 1):
            # entry looks like: "apple_pie/1005649"
            cls, name  = entry.strip().split("/")
            src        = images_dir / cls / f"{name}.jpg"
            dst_dir    = split_dir / cls
            dst_dir.mkdir(parents=True, exist_ok=True)
            dst        = dst_dir / f"{name}.jpg"
            if not dst.exists():
                shutil.copy2(src, dst)
            if i % 5000 == 0:
                print(f"  {i}/{len(entries)} done...")

        print(f"[{split}] Done → {split_dir}")

    print("\nDataset ready. Now run train_cnn.py with the env vars above.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare Food-101 dataset for training.")
    parser.add_argument(
        "--food101",
        required=True,
        help="Path to the extracted food-101 folder (contains images/ and meta/)",
    )
    args = parser.parse_args()
    prepare(Path(args.food101))
