import os
import json
import re
import pandas as pd
import pyarrow.parquet as pq

UNIFIED_DIR = os.path.abspath("datasets/processed/unified")

def clean_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"<[^>]*>", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

def save_unified_split(data, split_name, dataset_name):
    out_dir = os.path.join(UNIFIED_DIR, dataset_name)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{split_name}.jsonl")
    
    with open(out_path, "w", encoding="utf-8") as f:
        for item in data:
            json.dump(item, f, ensure_ascii=False)
            f.write("\n")
    print(f"Saved {len(data)} unified records for {dataset_name} ({split_name}) to {out_path}")

def unify_goemotions():
    print("Unifying GoEmotions...")
    raw_dir = "datasets/raw/goemotions"
    splits = ["train", "validation", "test"]
    
    # Emotion mapping (28 emotions index to labels)
    emotion_labels = [
        "admiration", "amusement", "anger", "annoyance", "approval", "caring", "confusion",
        "curiosity", "desire", "disappointment", "disapproval", "disgust", "embarrassment",
        "excitement", "fear", "gratitude", "grief", "joy", "love", "nervousness", "optimism",
        "pride", "realization", "relief", "remorse", "sadness", "surprise", "neutral"
    ]
    
    for split in splits:
        path = os.path.join(raw_dir, f"goemotions_{split}.jsonl")
        if not os.path.exists(path):
            continue
        
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                text = clean_text(record.get("text", ""))
                labels = record.get("labels", [])
                
                emotions = [emotion_labels[i] for i in labels if i < len(emotion_labels)]
                
                unified_rec = {
                    "dialogue_id": f"goemotions_{split}_{idx}",
                    "source_dataset": "GoEmotions",
                    "context": {
                        "topic": "",
                        "persona": [],
                        "situation": "",
                        "metadata": {}
                    },
                    "messages": [
                        {
                            "role": "user",
                            "text": text,
                            "annotations": {
                                "emotion": emotions,
                                "act": "",
                                "intents": [],
                                "other": {}
                            }
                        }
                    ]
                }
                unified_data.append(unified_rec)
                
        save_unified_split(unified_data, split, "goemotions")

def unify_dailydialog():
    print("Unifying DailyDialog...")
    raw_dir = "datasets/raw/dailydialog"
    splits = ["train", "validation", "test"]
    
    for split in splits:
        path = os.path.join(raw_dir, f"dailydialog_{split}.jsonl")
        if not os.path.exists(path):
            continue
        
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                
                dialog = record.get("dialog", [])
                act_label = record.get("act_label", [])
                emotion_label = record.get("emotion_label", [])
                
                # Sometime arrays are not matching, fallback to defaults
                messages = []
                for turn_idx, text in enumerate(dialog):
                    role = "user" if turn_idx % 2 == 0 else "assistant"
                    
                    act = ""
                    if isinstance(act_label, list) and turn_idx < len(act_label):
                        act = str(act_label[turn_idx])
                    elif isinstance(act_label, int):
                        act = str(act_label)
                        
                    emotion = []
                    if isinstance(emotion_label, list) and turn_idx < len(emotion_label):
                        emotion = [str(emotion_label[turn_idx])]
                    elif isinstance(emotion_label, int):
                        emotion = [str(emotion_label)]
                        
                    messages.append({
                        "role": role,
                        "text": clean_text(text),
                        "annotations": {
                            "emotion": emotion,
                            "act": act,
                            "intents": [],
                            "other": {}
                        }
                    })
                
                unified_rec = {
                    "dialogue_id": f"dailydialog_{split}_{idx}",
                    "source_dataset": "DailyDialog",
                    "context": {
                        "topic": "",
                        "persona": [],
                        "situation": "",
                        "metadata": {}
                    },
                    "messages": messages
                }
                unified_data.append(unified_rec)
                
        save_unified_split(unified_data, split, "dailydialog")

def unify_counselchat():
    print("Unifying CounselChat...")
    path = "datasets/raw/counselchat/20220401_counsel_chat.csv"
    if not os.path.exists(path):
        return
    
    df = pd.read_csv(path)
    unified_data = []
    
    for idx, row in df.iterrows():
        question_id = str(row.get("questionID", idx))
        title = clean_text(str(row.get("questionTitle", "")))
        text = clean_text(str(row.get("questionText", "")))
        answer = clean_text(str(row.get("answerText", "")))
        topic = clean_text(str(row.get("topic", "")))
        
        messages = [
            {
                "role": "user",
                "text": text,
                "annotations": {
                    "emotion": [],
                    "act": "",
                    "intents": [],
                    "other": {}
                }
            },
            {
                "role": "assistant",
                "text": answer,
                "annotations": {
                    "emotion": [],
                    "act": "",
                    "intents": [],
                    "other": {
                        "therapistInfo": str(row.get("therapistInfo", "")),
                        "upvotes": int(row.get("upvotes", 0)) if pd.notna(row.get("upvotes")) else 0
                    }
                }
            }
        ]
        
        unified_rec = {
            "dialogue_id": f"counselchat_{question_id}_{idx}",
            "source_dataset": "CounselChat",
            "context": {
                "topic": topic,
                "persona": [],
                "situation": title,
                "metadata": {}
            },
            "messages": messages
        }
        unified_data.append(unified_rec)
        
    # Split: 80% train, 10% val, 10% test
    total = len(unified_data)
    train_end = int(total * 0.8)
    val_end = int(total * 0.9)
    
    save_unified_split(unified_data[:train_end], "train", "counselchat")
    save_unified_split(unified_data[train_end:val_end], "validation", "counselchat")
    save_unified_split(unified_data[val_end:], "test", "counselchat")

def unify_personachat():
    print("Unifying PersonaChat...")
    raw_dir = "datasets/raw/personachat"
    splits = ["train", "validation"]
    for split in splits:
        path = os.path.join(raw_dir, f"personachat_{split}.jsonl")
        if not os.path.exists(path):
            continue
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                persona = record.get("personality", [])
                messages = []
                for turn in record.get("utterances", []):
                    hist = turn.get("history", [])
                    for t_idx, text in enumerate(hist):
                        role = "user" if t_idx % 2 == 0 else "assistant"
                        messages.append({
                            "role": role,
                            "text": clean_text(text),
                            "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                        })
                unified_rec = {
                    "dialogue_id": f"personachat_{split}_{idx}",
                    "source_dataset": "PersonaChat",
                    "context": {"topic": "", "persona": persona, "situation": "", "metadata": {}},
                    "messages": messages
                }
                unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "personachat")

def unify_emotionlines():
    print("Unifying EmotionLines...")
    raw_dir = "datasets/raw/emotionlines"
    splits = ["train", "validation", "test"]
    for split in splits:
        path = os.path.join(raw_dir, f"emotionlines_{split}.jsonl")
        if not os.path.exists(path):
            continue
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                unified_rec = {
                    "dialogue_id": f"emotionlines_{split}_{idx}",
                    "source_dataset": "EmotionLines",
                    "context": {"topic": "", "persona": [], "situation": "", "metadata": {}},
                    "messages": [{
                        "role": record.get("speaker", "unknown"),
                        "text": clean_text(record.get("utterance", "")),
                        "annotations": {"emotion": [record.get("emotion", "")], "act": "", "intents": [], "other": {}}
                    }]
                }
                unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "emotionlines")

def unify_cornell():
    print("Unifying Cornell Movie Dialogs...")
    path = "datasets/raw/cornell/cornell_movie_lines.jsonl"
    if not os.path.exists(path):
        return
    unified_data = []
    with open(path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            if not line.strip():
                continue
            record = json.loads(line)
            unified_rec = {
                "dialogue_id": f"cornell_{record.get('lineID', idx)}",
                "source_dataset": "Cornell",
                "context": {"topic": "", "persona": [], "situation": "", "metadata": {"movieID": record.get("movieID", "")}},
                "messages": [{
                    "role": record.get("characterName", "unknown"),
                    "text": clean_text(record.get("utterance", "")),
                    "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                }]
            }
            unified_data.append(unified_rec)
    total = len(unified_data)
    train_end = int(total * 0.8)
    val_end = int(total * 0.9)
    save_unified_split(unified_data[:train_end], "train", "cornell")
    save_unified_split(unified_data[train_end:val_end], "validation", "cornell")
    save_unified_split(unified_data[val_end:], "test", "cornell")

def unify_ultrachat():
    print("Unifying UltraChat...")
    raw_dir = "datasets/raw/ultrachat"
    files_map = {
        "train": ["ultrachat_train_sft.jsonl", "ultrachat_train_gen.jsonl"],
        "test": ["ultrachat_test_sft.jsonl", "ultrachat_test_gen.jsonl"]
    }
    for split, filenames in files_map.items():
        unified_data = []
        for filename in filenames:
            path = os.path.join(raw_dir, filename)
            if not os.path.exists(path):
                continue
            with open(path, "r", encoding="utf-8") as f:
                for idx, line in enumerate(f):
                    if not line.strip():
                        continue
                    record = json.loads(line)
                    raw_messages = record.get("messages", [])
                    messages = []
                    for m in raw_messages:
                        messages.append({
                            "role": m.get("role", "user"),
                            "text": clean_text(m.get("content", "")),
                            "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                        })
                    unified_rec = {
                        "dialogue_id": f"ultrachat_{record.get('prompt_id', idx)}",
                        "source_dataset": "UltraChat",
                        "context": {"topic": "", "persona": [], "situation": record.get("prompt", ""), "metadata": {}},
                        "messages": messages
                    }
                    unified_data.append(unified_rec)
        if unified_data:
            save_unified_split(unified_data, split, "ultrachat")

def unify_oasst():
    print("Unifying OpenAssistant...")
    raw_dir = "datasets/raw/oasst"
    splits = ["train", "validation"]
    for split in splits:
        path = os.path.join(raw_dir, f"oasst_{split}.jsonl")
        if not os.path.exists(path):
            continue
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                unified_rec = {
                    "dialogue_id": f"oasst_{record.get('message_tree_id', idx)}",
                    "source_dataset": "OpenAssistant",
                    "context": {"topic": "", "persona": [], "situation": "", "metadata": {"message_id": record.get("message_id"), "parent_id": record.get("parent_id")}},
                    "messages": [{
                        "role": "user" if record.get("role") == "user" else "assistant",
                        "text": clean_text(record.get("text", "")),
                        "annotations": {"emotion": [], "act": "", "intents": [], "other": {"lang": record.get("lang"), "rank": record.get("rank")}}
                    }]
                }
                unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "oasst")

def unify_empathetic():
    print("Unifying EmpatheticDialogues...")
    raw_dir = "datasets/raw/empathetic_dialogues"
    if not os.path.exists(raw_dir):
        raw_dir = "datasets/raw/empathetic"
    splits = ["train", "validation", "test"]
    for split in splits:
        path = os.path.join(raw_dir, f"empathetic_{split}.jsonl")
        if not os.path.exists(path):
            continue
        conversations = {}
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                record = json.loads(line)
                conv_id = record.get("conv_id")
                if not conv_id:
                    continue
                if conv_id not in conversations:
                    conversations[conv_id] = {
                        "situation": record.get("prompt", ""),
                        "topic": record.get("context", ""),
                        "turns": []
                    }
                conversations[conv_id]["turns"].append(record)
        unified_data = []
        for conv_id, info in conversations.items():
            sorted_turns = sorted(info["turns"], key=lambda x: x.get("utterance_idx", 0))
            messages = []
            for t in sorted_turns:
                role = "user" if t.get("speaker_idx", 0) == 0 else "assistant"
                messages.append({
                    "role": role,
                    "text": clean_text(t.get("utterance", "")),
                    "annotations": {"emotion": [info["topic"]], "act": "", "intents": [], "other": {}}
                })
            unified_rec = {
                "dialogue_id": f"empathetic_{conv_id}",
                "source_dataset": "EmpatheticDialogues",
                "context": {"topic": info["topic"], "persona": [], "situation": info["situation"], "metadata": {}},
                "messages": messages
            }
            unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "empathetic")

def unify_wizard():
    print("Unifying Wizard of Wikipedia...")
    raw_dir = "datasets/raw/wizard"
    splits = ["train", "validation", "test"]
    for split in splits:
        path = os.path.join(raw_dir, f"wizard_{split}.jsonl")
        if not os.path.exists(path):
            continue
        unified_data = []
        with open(path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if not line.strip():
                    continue
                record = json.loads(line)
                posts = record.get("post", [])
                response = record.get("response", "")
                topics = record.get("topics", [])
                messages = []
                for p_idx, p in enumerate(posts):
                    if isinstance(p, list):
                        p = " ".join([str(x) for x in p])
                    role = "user" if p_idx % 2 == 0 else "assistant"
                    messages.append({
                        "role": role,
                        "text": clean_text(str(p)),
                        "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                    })
                if response:
                    if isinstance(response, list):
                        response = " ".join([str(x) for x in response])
                    messages.append({
                        "role": "assistant",
                        "text": clean_text(str(response)),
                        "annotations": {"emotion": [], "act": "", "intents": [], "other": {"knowledge": record.get("knowledge", "")}}
                    })
                unified_rec = {
                    "dialogue_id": f"wizard_{split}_{idx}",
                    "source_dataset": "Wizard of Wikipedia",
                    "context": {"topic": ", ".join(topics) if isinstance(topics, list) else str(topics), "persona": [], "situation": "", "metadata": {}},
                    "messages": messages
                }
                unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "wizard")

def unify_multiwoz():
    print("Unifying MultiWOZ...")
    raw_dir = "datasets/raw/multiwoz"
    splits = ["train", "validation", "test"]
    for split in splits:
        path = os.path.join(raw_dir, f"multi_woz_v22_{split}.parquet")
        if not os.path.exists(path):
            continue
        unified_data = []
        pf = pq.ParquetFile(path)
        for batch in pf.iter_batches(batch_size=2000):
            records = batch.to_pylist()
            for r in records:
                turns = r.get("turns", {})
                speakers = turns.get("speaker", [])
                utterances = turns.get("utterance", [])
                messages = []
                for t_idx in range(len(utterances)):
                    spk = speakers[t_idx] if t_idx < len(speakers) else 0
                    role = "user" if spk == 0 else "assistant"
                    messages.append({
                        "role": role,
                        "text": clean_text(utterances[t_idx]),
                        "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                    })
                unified_rec = {
                    "dialogue_id": f"multiwoz_{r.get('dialogue_id', '')}",
                    "source_dataset": "MultiWOZ",
                    "context": {"topic": "", "persona": [], "situation": "", "metadata": {"services": r.get("services", [])}},
                    "messages": messages
                }
                unified_data.append(unified_rec)
        save_unified_split(unified_data, split, "multiwoz")

def unify_slimorca():
    print("Unifying SlimOrca...")
    path = "datasets/raw/slimorca/slimorca_train.jsonl"
    if not os.path.exists(path):
        return
    unified_data = []
    with open(path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            if not line.strip():
                continue
            record = json.loads(line)
            convs = record.get("conversations", [])
            messages = []
            for c in convs:
                role_raw = c.get("from", "")
                if role_raw == "human":
                    role = "user"
                elif role_raw == "system":
                    role = "system"
                else:
                    role = "assistant"
                messages.append({
                    "role": role,
                    "text": clean_text(c.get("value", "")),
                    "annotations": {"emotion": [], "act": "", "intents": [], "other": {}}
                })
            unified_rec = {
                "dialogue_id": f"slimorca_{idx}",
                "source_dataset": "SlimOrca",
                "context": {"topic": "", "persona": [], "situation": "", "metadata": {}},
                "messages": messages
            }
            unified_data.append(unified_rec)
    total = len(unified_data)
    train_end = int(total * 0.8)
    val_end = int(total * 0.9)
    save_unified_split(unified_data[:train_end], "train", "slimorca")
    save_unified_split(unified_data[train_end:val_end], "validation", "slimorca")
    save_unified_split(unified_data[val_end:], "test", "slimorca")

def main():
    unify_goemotions()
    unify_dailydialog()
    unify_counselchat()
    unify_personachat()
    unify_emotionlines()
    unify_cornell()
    unify_ultrachat()
    unify_oasst()
    unify_empathetic()
    unify_wizard()
    unify_multiwoz()
    unify_slimorca()

if __name__ == "__main__":
    main()
