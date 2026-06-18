import os
import json
import zipfile
import requests
import csv
import random

def download_goemotions(dest_dir: str = "datasets/raw/goemotions"):
    """Download GoEmotions dataset using public CSV files.
    Attempts:
    1️⃣ Load via Hugging Face (requires valid identifier).
    2️⃣ Download CSV files directly from Google storage.
    No placeholders are created; failures are reported.
    """
    os.makedirs(dest_dir, exist_ok=True)
    # 1️⃣ HF download
    try:
        from datasets import load_dataset
        token = os.getenv("HF_TOKEN")
        ds = load_dataset("go_emotions", token=token) if token else load_dataset("go_emotions")
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"goemotions_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"GoEmotions downloaded via HF to {dest_dir}")
        return
    except Exception as e:
        print(f"HF download failed ({e}); falling back to CSV download.")

    # 2️⃣ Direct CSV download
    try:
        urls = [
            "https://storage.googleapis.com/gresearch/goemotions/data/full_dataset/goemotions_1.csv",
            "https://storage.googleapis.com/gresearch/goemotions/data/full_dataset/goemotions_2.csv",
            "https://storage.googleapis.com/gresearch/goemotions/data/full_dataset/goemotions_3.csv",
        ]
        records = []
        for url in urls:
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            reader = csv.DictReader(resp.text.splitlines())
            for row in reader:
                # Convert label string like "[12, 5]" to list
                lbl = row.get("labels")
                try:
                    labels = eval(lbl) if isinstance(lbl, str) else []
                except Exception:
                    labels = []
                records.append({"text": row.get("text", ""), "labels": labels})
        random.shuffle(records)
        n = len(records)
        splits = {
            "train": records[: int(0.7 * n)],
            "validation": records[int(0.7 * n): int(0.85 * n)],
            "test": records[int(0.85 * n):],
        }
        for split, recs in splits.items():
            out_path = os.path.join(dest_dir, f"goemotions_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as out:
                for rec in recs:
                    json.dump(rec, out)
                    out.write("\n")
        print(f"GoEmotions CSV download completed to {dest_dir}")
        return
    except Exception as csv_err:
        print(f"CSV download failed: {csv_err}")
        raise

if __name__ == "__main__":
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    dest = os.path.join(root, "datasets", "raw", "goemotions")
    download_goemotions(dest)
