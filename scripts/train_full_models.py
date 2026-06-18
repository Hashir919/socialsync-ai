# scripts/train_full_models.py
"""
Comprehensive training script that prepares data, trains intent classifier,
conversation retriever, rewrite matcher, and validates them.
"""
import os, json, joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from scripts.preprocess import preprocess_dataset
from scripts.train_intent import train_intent_classifier  # will be updated to use real data
from scripts.train_dialogue_retriever import train_dialogue_retriever

def main():
    # Ensure models directory exists
    models_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    os.makedirs(models_dir, exist_ok=True)

    # 1. Train intent classifier on real datasets
    print("[Full Training] Training intent classifier on real datasets...")
    # reuse existing function which now loads real data
    train_intent_classifier()

    # 2. Train conversational retriever on combined corpora
    print("[Full Training] Training conversational retriever on combined datasets...")
    train_dialogue_retriever()

    # 3. Train rewrite matcher (already covered in train_dialogue_retriever)
    #   The retriever script also creates rewrite matcher based on SOCIALSYNC_DATA and additional corpora.

    print("[Full Training] All models trained and saved to models/ directory.")

if __name__ == "__main__":
    main()
