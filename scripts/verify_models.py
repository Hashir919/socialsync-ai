# scripts/verify_models.py
"""
Verification script to ensure required model pickle files exist and can be loaded.
It prints a table with model name, path, and load status.
"""
import os
import joblib
import json
from pathlib import Path

MODELS = {
    "emotion_classifier": "models/emotion_classifier.pkl",
    "intent_classifier": "models/intent_classifier.pkl",
    "conversational_retriever": "models/conversational_retriever.pkl",
    "rewrite_matcher": "models/rewrite_matcher.pkl",
}

def verify_model(name, rel_path):
    path = Path(__file__).resolve().parents[1] / rel_path
    if not path.is_file():
        return {"path": str(path), "status": "MISSING"}
    try:
        _ = joblib.load(path)
        return {"path": str(path), "status": "OK"}
    except Exception as e:
        return {"path": str(path), "status": f"ERROR: {e}"}

if __name__ == "__main__":
    results = {name: verify_model(name, p) for name, p in MODELS.items()}
    print(json.dumps(results, indent=2))
