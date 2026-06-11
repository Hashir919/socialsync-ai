import os
import json
import requests

def download_cornell(dest_dir: str = "../datasets/raw/cornell"):
    """Download Cornell Movie Dialogs dataset."""
    os.makedirs(dest_dir, exist_ok=True)
    
    # Cornell movie dialogs is available on HF
    try:
        from datasets import load_dataset
        print("Loading Cornell Movie Dialogs via datasets...")
        ds = load_dataset("cornell_movie_dialog")
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"cornell_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"Cornell Movie Dialogs downloaded to {dest_dir}")
    except Exception as e:
        print(f"HuggingFace load failed: {e}. Writing fallback/sample data.")
        sample_data = [
            {"movie_id": "m0", "utterances": ["Hi", "Hello there"]}
        ]
        out_path = os.path.join(dest_dir, "cornell_train.jsonl")
        with open(out_path, "w", encoding="utf-8") as f:
            for item in sample_data:
                json.dump(item, f)
                f.write("\n")

if __name__ == "__main__":
    download_cornell()
