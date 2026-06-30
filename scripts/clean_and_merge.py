import os
import json
import hashlib

UNIFIED_DIR = os.path.abspath("datasets/processed/unified")
CLEANED_DIR = os.path.abspath("datasets/processed/cleaned")
MASTER_PATH = os.path.join(CLEANED_DIR, "master_dataset.jsonl")

def get_dialogue_hash(record):
    # Hash messages text & role sequence
    hasher = hashlib.md5()
    for msg in record.get("messages", []):
        text = str(msg.get("text") or "").strip()
        role = str(msg.get("role") or "").strip()
        hasher.update(f"{role}:{text}".encode('utf-8'))
    # Include situation/context if present
    context = record.get("context", {})
    situation = str(context.get("situation") or "").strip()
    topic = str(context.get("topic") or "").strip()
    hasher.update(f"{situation}:{topic}".encode('utf-8'))
    return hasher.hexdigest()

def is_valid_record(record):
    # Check structure
    if not isinstance(record, dict):
        return False
    if "messages" not in record or not isinstance(record["messages"], list):
        return False
    if len(record["messages"]) == 0:
        return False
    # Validate each message has text
    has_text = False
    for msg in record["messages"]:
        if not isinstance(msg, dict):
            return False
        text = str(msg.get("text") or "").strip()
        if text:
            has_text = True
    if not has_text:
        return False
    return True

def clean_text(text):
    text = str(text or "")
    # Normalize spacing
    import re
    text = re.sub(r"\s+", " ", text).strip()
    return text

def main():
    os.makedirs(CLEANED_DIR, exist_ok=True)
    seen_hashes = set()
    total_duplicates = 0
    total_invalid = 0
    total_master_records = 0
    
    datasets = os.listdir(UNIFIED_DIR)
    
    with open(MASTER_PATH, "w", encoding="utf-8") as master_f:
        for dataset_name in datasets:
            dataset_dir = os.path.join(UNIFIED_DIR, dataset_name)
            if not os.path.isdir(dataset_dir):
                continue
                
            cleaned_dataset_dir = os.path.join(CLEANED_DIR, dataset_name)
            os.makedirs(cleaned_dataset_dir, exist_ok=True)
            
            for file_name in os.listdir(dataset_dir):
                if not file_name.endswith(".jsonl"):
                    continue
                    
                in_path = os.path.join(dataset_dir, file_name)
                out_path = os.path.join(cleaned_dataset_dir, file_name)
                
                cleaned_records = []
                
                with open(in_path, "r", encoding="utf-8") as f:
                    for line in f:
                        if not line.strip():
                            continue
                        try:
                            record = json.loads(line)
                        except Exception:
                            total_invalid += 1
                            continue
                            
                        if not is_valid_record(record):
                            total_invalid += 1
                            continue
                            
                        # Normalize text in messages
                        for msg in record["messages"]:
                            msg["text"] = clean_text(msg.get("text", ""))
                            
                        # Normalize text in situation/topic
                        if "context" in record:
                            record["context"]["situation"] = clean_text(record["context"].get("situation", ""))
                            record["context"]["topic"] = clean_text(record["context"].get("topic", ""))
                            
                        # Check duplicate
                        r_hash = get_dialogue_hash(record)
                        if r_hash in seen_hashes:
                            total_duplicates += 1
                            continue
                        
                        seen_hashes.add(r_hash)
                        cleaned_records.append(record)
                        
                        # Write to master dataset
                        json.dump(record, master_f, ensure_ascii=False)
                        master_f.write("\n")
                        total_master_records += 1
                        
                with open(out_path, "w", encoding="utf-8") as out_f:
                    for record in cleaned_records:
                        json.dump(record, out_f, ensure_ascii=False)
                        out_f.write("\n")
                        
            print(f"Cleaned {dataset_name}")
            
    print("\nProcessing summary:")
    print(f"Total Master Records: {total_master_records}")
    print(f"Total Duplicates Removed: {total_duplicates}")
    print(f"Total Invalid Records Removed: {total_invalid}")

if __name__ == "__main__":
    main()
