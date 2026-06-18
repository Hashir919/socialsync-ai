import os
import json

def download_cornell(dest_dir: str = "datasets/raw/cornell"):
    """Download Cornell Movie Dialogs dataset.
    Attempts:
    1️⃣ Load via Hugging Face using spawn99/CornellMovieDialogCorpus (script-less/parquet-based).
    No placeholder data is generated; failures raise an exception.
    """
    os.makedirs(dest_dir, exist_ok=True)
    try:
        from datasets import load_dataset
        print("Loading Cornell Movie Dialogs via datasets (spawn99/CornellMovieDialogCorpus)...")
        ds = load_dataset("spawn99/CornellMovieDialogCorpus", token=os.getenv("HF_TOKEN"))
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"cornell_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"Cornell Movie Dialogs downloaded to {dest_dir}")
    except Exception as e:
        print(f"Cornell download failed: {e}")
        raise

if __name__ == "__main__":
    root_dir = os.path.join(os.path.dirname(__file__), "..")
    dest = os.path.join(root_dir, "datasets", "raw", "cornell")
    download_cornell(dest)
