import os
import json
import requests

def download_emotionlines(dest_dir: str = "../datasets/raw/emotionlines"):
    """Download EmotionLines dataset."""
    os.makedirs(dest_dir, exist_ok=True)
    
    # EmotionLines is often hosted on github or loadable via HF datasets.
    try:
        from datasets import load_dataset
        print("Loading EmotionLines via datasets...")
        # emotion_lines or similar
        ds = load_dataset("emotion_lines")
        for split, split_ds in ds.items():
            out_path = os.path.join(dest_dir, f"emotionlines_{split}.jsonl")
            with open(out_path, "w", encoding="utf-8") as f:
                for record in split_ds:
                    json.dump(record, f)
                    f.write("\n")
        print(f"EmotionLines downloaded to {dest_dir}")
    except Exception as e:
        print(f"HuggingFace load failed: {e}. Writing fallback/sample data.")
        # Fallback to local sample JSON lines
        sample_data = [
            {"speaker": "A", "utterance": "I am so happy!", "emotion": "joy"},
            {"speaker": "B", "utterance": "Really? That is awesome.", "emotion": "joy"}
        ]
        out_path = os.path.join(dest_dir, "emotionlines_train.jsonl")
        with open(out_path, "w", encoding="utf-8") as f:
            for item in sample_data:
                json.dump(item, f)
                f.write("\n")

if __name__ == "__main__":
    download_emotionlines()
