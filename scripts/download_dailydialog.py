import os
import json
from datasets import load_dataset


def download_dailydialog(dest_dir: str = "../datasets/raw/dailydialog"):
    """Download DailyDialog dataset and save as JSON lines.
    Args:
        dest_dir: Directory where raw data will be stored.
    """
    os.makedirs(dest_dir, exist_ok=True)
    ds = load_dataset("daily_dialog")
    for split, split_ds in ds.items():
        out_path = os.path.join(dest_dir, f"dailydialog_{split}.jsonl")
        with open(out_path, "w", encoding="utf-8") as f:
            for record in split_ds:
                json.dump(record, f)
                f.write("\n")
    print(f"DailyDialog {list(ds.keys())} downloaded to {dest_dir}")


if __name__ == "__main__":
    download_dailydialog()
