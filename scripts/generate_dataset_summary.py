import os
import json
from pathlib import Path

def count_lines(file_path: Path) -> int:
    with open(file_path, "r", encoding="utf-8") as f:
        return sum(1 for _ in f)

def extract_labels(file_path: Path) -> set:
    labels = set()
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                data = json.loads(line)
                if "labels" in data:
                    for lbl in data["labels"]:
                        labels.add(str(lbl))
                elif "emotion" in data:
                    labels.add(str(data["emotion"]))
                elif "sentiment" in data:
                    labels.add(str(data["sentiment"]))
                elif "dialogue" in data:
                    # not a label
                    pass
            except json.JSONDecodeError:
                continue
    return labels

def is_placeholder(count: int) -> bool:
    # placeholder datasets typically have small number of records (e.g., <30)
    return count < 30

def main():
    raw_dir = Path(__file__).resolve().parents[1] / "datasets" / "raw"
    summary_path = Path(__file__).resolve().parents[1] / "DATASET_SUMMARY.md"
    lines = ["# Dataset Summary", ""]
    for dataset_dir in raw_dir.iterdir():
        if not dataset_dir.is_dir():
            continue
        dataset_name = dataset_dir.name
        lines.append(f"## {dataset_name}")
        total_records = 0
        split_counts = {}
        all_labels = set()
        placeholder = False
        for split in ["train", "validation", "test"]:
            file_path = dataset_dir / f"{dataset_name}_{split}.jsonl"
            if not file_path.exists():
                continue
            count = count_lines(file_path)
            split_counts[split] = count
            total_records += count
            if is_placeholder(count):
                placeholder = True
            all_labels.update(extract_labels(file_path))
        lines.append(f"- **Record count**: {total_records}")
        for split, cnt in split_counts.items():
            lines.append(f"  - {split}: {cnt}")
        lines.append(f"- **Labels/classes**: {', '.join(sorted(all_labels)) if all_labels else 'N/A'}")
        lines.append(f"- **Placeholder data**: {'Yes' if placeholder else 'No'}")
        lines.append("")
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Dataset summary written to {summary_path}")

if __name__ == "__main__":
    main()
