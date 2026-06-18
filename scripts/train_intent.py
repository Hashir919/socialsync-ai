import os
import json
import joblib
from collections import Counter
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

COACHING_PATH = os.path.join(os.path.dirname(__file__), "..", "backend", "coaching_dataset.json")
MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "models")

def load_intent_data():
    if not os.path.exists(COACHING_PATH):
        raise FileNotFoundError(f"Coaching dataset not found at {COACHING_PATH}. Please run expand_coaching_dataset.py first.")
    
    with open(COACHING_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    texts = []
    labels = []
    for item in data:
        text = item.get("text", "").strip()
        context = item.get("context", "").strip().lower()
        if text and context:
            texts.append(text)
            labels.append(context)
            
    return texts, labels

def train_intent_classifier():
    texts, labels = load_intent_data()
    print(f"[Intent Training] Loaded {len(texts)} samples for intent classification.")
    
    dist = Counter(labels)
    print("[Intent Training] Class distribution:")
    for lbl, count in dist.items():
        print(f"  {lbl}: {count}")
        
    X_train, X_val, y_train, y_val = train_test_split(
        texts, labels, test_size=0.15, random_state=42, stratify=labels
    )
    
    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(stop_words='english', ngram_range=(1, 2), min_df=1)),
        ("clf", LogisticRegression(max_iter=1000, C=2.0, class_weight='balanced', random_state=42))
    ])
    
    pipeline.fit(X_train, y_train)
    y_pred = pipeline.predict(X_val)
    
    val_acc = accuracy_score(y_val, y_pred)
    print(f"[Intent Training] Validation accuracy: {val_acc:.4f}")
    
    clf_report = classification_report(y_val, y_pred, zero_division=0)
    print(clf_report)
    
    conf_mat = confusion_matrix(y_val, y_pred, labels=sorted(list(dist.keys())))
    print("[Intent Training] Confusion Matrix:")
    print(conf_mat)
    
    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(pipeline, os.path.join(MODELS_DIR, "intent_classifier.pkl"))
    
    # Save training report
    report_path = os.path.join(MODELS_DIR, "intent_training_report.txt")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("=== INTENT TRAINING REPORT ===\n")
        f.write(f"Validation Accuracy: {val_acc:.4f}\n\n")
        f.write("Class Distribution:\n")
        for lbl, count in sorted(dist.items()):
            f.write(f"  {lbl}: {count}\n")
        f.write("\nClassification Report:\n")
        f.write(clf_report)
        f.write("\nConfusion Matrix:\n")
        f.write(str(conf_mat))
        
    print(f"[Intent Training] Model and report saved successfully.")

if __name__ == "__main__":
    train_intent_classifier()
