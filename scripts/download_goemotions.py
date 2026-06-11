import os
import json
from datasets import load_dataset


def download_goemotions(dest_dir: str = "../datasets/raw/goemotions"):
    """Download GoEmotions dataset and save as JSON lines.
    Args:
        dest_dir: Directory where raw data will be stored.
    """
    os.makedirs(dest_dir, exist_ok=True)
    ds = load_dataset("go_emotions")
    for split, split_ds in ds.items():
        out_path = os.path.join(dest_dir, f"goemotions_{split}.jsonl")
        with open(out_path, "w", encoding="utf-8") as f:
            for record in split_ds:
                json.dump(record, f)
                f.write("\n")
    print(f"GoEmotions {list(ds.keys())} downloaded to {dest_dir}")


if __name__ == "__main__":
    download_goemotions()
