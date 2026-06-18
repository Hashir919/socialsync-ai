import os
import json

def download_personachat(dest_dir: str = "datasets/raw/personachat"):
    """Download PersonaChat dataset.
    Attempts:
    1️⃣ Load via Hugging Face using AlekseyKorshuk/persona-chat (script-less/parquet-based).
    No placeholder data is generated; failures raise an exception.
    """
    os.makedirs(dest_dir, exist_ok=True)
    try:
        from datasets import load_dataset
        print("Loading PersonaChat via datasets (AlekseyKorshuk/persona-chat)...")
        ds = load_dataset("AlekseyKorshuk/persona-chat", token=os.getenv("HF_TOKEN"))
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"personachat_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"PersonaChat downloaded to {dest_dir}")
    except Exception as e:
        print(f"PersonaChat download failed: {e}")
        raise

if __name__ == "__main__":
    root_dir = os.path.join(os.path.dirname(__file__), "..")
    dest = os.path.join(root_dir, "datasets", "raw", "personachat")
    download_personachat(dest)
