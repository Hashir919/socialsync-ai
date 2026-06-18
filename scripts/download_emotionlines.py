import os
import json
import csv
import requests
import random

def download_emotionlines(dest_dir: str = "datasets/raw/emotionlines"):
    """Download MELD dataset (as a replacement for EmotionLines) directly from GitHub CSVs.
    Attempts:
    1️⃣ Download train, validation, and test CSV files from declare-lab/MELD GitHub repo.
    No placeholder data is generated; failures raise an exception.
    """
    os.makedirs(dest_dir, exist_ok=True)
    urls = {
        "train": "https://raw.githubusercontent.com/declare-lab/MELD/master/data/MELD/train_sent_emo.csv",
        "validation": "https://raw.githubusercontent.com/declare-lab/MELD/master/data/MELD/dev_sent_emo.csv",
        "test": "https://raw.githubusercontent.com/declare-lab/MELD/master/data/MELD/test_sent_emo.csv"
    }
    try:
        for split, url in urls.items():
            print(f"Downloading MELD {split} CSV from GitHub...")
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            reader = csv.DictReader(resp.text.splitlines())
            out_path = os.path.join(dest_dir, f"emotionlines_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for row in reader:
                    record = {
                        "speaker": row.get("Speaker", ""),
                        "utterance": row.get("Utterance", ""),
                        "emotion": row.get("Emotion", "").lower()
                    }
                    json.dump(record, f)
                    f.write("\n")
        print(f"EmotionLines (MELD replacement) downloaded and structured successfully at {dest_dir}")
    except Exception as e:
        print(f"EmotionLines download failed: {e}")
        raise

if __name__ == "__main__":
    root_dir = os.path.join(os.path.dirname(__file__), "..")
    dest = os.path.join(root_dir, "datasets", "raw", "emotionlines")
    download_emotionlines(dest)
