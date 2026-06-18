import os
import json

def download_dailydialog(dest_dir: str = "datasets/raw/dailydialog"):
    """Download DailyDialog dataset and save as JSON lines.
    Attempts:
    1️⃣ Load via Hugging Face using DeepPavlov/daily_dialog (script-less/parquet-based).
    No placeholder data is generated; failures raise an exception.
    """
    os.makedirs(dest_dir, exist_ok=True)
    try:
        from datasets import load_dataset
        print("Attempting to download daily_dialog via DeepPavlov/daily_dialog...")
        ds = load_dataset("DeepPavlov/daily_dialog", token=os.getenv("HF_TOKEN"))
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"dailydialog_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"DailyDialog {list(ds.keys())} downloaded successfully to {dest_dir}")
    except Exception as e:
        print(f"DailyDialog download failed: {e}")
        raise

if __name__ == "__main__":
    root_dir = os.path.join(os.path.dirname(__file__), "..")
    dest = os.path.join(root_dir, "datasets", "raw", "dailydialog")
    download_dailydialog(dest)
