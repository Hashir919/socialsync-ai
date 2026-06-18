import os
import json
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline


def build_rewrite_search_text(item):
    return " ".join(
        part
        for part in [
            item.get("context", ""),
            item.get("category", ""),
            item.get("emotion", ""),
            item.get("original_message", ""),
        ]
        if part
    )

def load_data_or_fallback():
    # 1. Custom socialsync dataset
    dataset_path = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")
    if not os.path.exists(dataset_path):
        print("Generating socialsync_dataset.json first...")
        from generate_custom_dataset import generate_dataset
        generate_dataset()
        
    with open(dataset_path, "r", encoding="utf-8") as f:
        social_data = json.load(f)
        
    # 2. Extract training samples
    texts = []
    emotions = []
    anxiety_scores = []
    
    for item in social_data:
        texts.append(item["original_message"])
        emotions.append(item["emotion"])
        anxiety_scores.append(item["anxiety_score"])
        
    # Add a few extra standard dialog/emotion examples to broaden the scope
    fallback_emotions = [
        ("I don't think I can do this presentation, my hands are shaking.", "Anxiety", 0.95),
        ("Why are you not answering? This is incredibly frustrating.", "Anger", 0.60),
        ("I'm so excited to catch up this weekend!", "Joy", 0.10),
        ("I feel extremely down today, nothing is going right.", "Sadness", 0.80),
        ("What a pleasant surprise! I wasn't expecting this.", "Surprise", 0.30),
        ("Hello, how are you doing today?", "Neutral", 0.20),
    ]
    for text, emo, score in fallback_emotions:
        texts.append(text)
        emotions.append(emo)
        anxiety_scores.append(score)
        
    return texts, emotions, anxiety_scores, social_data

def train_and_save():
    print("[Training Pipeline] Starting model training...")
    texts, emotions, anxiety_scores, social_data = load_data_or_fallback()
    
    # 1. Train Emotion/Anxiety Classifier
    # We will build a pipeline: TF-IDF Vectorizer -> Logistic Regression Classifier
    emotion_pipeline = Pipeline([
        ('tfidf', TfidfVectorizer(stop_words='english', min_df=1, ngram_range=(1, 2))),
        ('clf', LogisticRegression(max_iter=1500, C=1.5, class_weight='balanced'))
    ])
    
    print(f"[Training Pipeline] Training Emotion Classifier on {len(texts)} samples...")
    emotion_pipeline.fit(texts, emotions)
    
    # Simple evaluation
    train_acc = emotion_pipeline.score(texts, emotions)
    print(f"[Training Pipeline] Emotion Classifier trained. Accuracy: {train_acc * 100:.2f}%")
    
    # Save the pipeline
    models_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    os.makedirs(models_dir, exist_ok=True)
    emotion_model_path = os.path.join(models_dir, "emotion_classifier.pkl")
    joblib.dump(emotion_pipeline, emotion_model_path)
    print(f"[Training Pipeline] Emotion model saved to {emotion_model_path}")
    
    # 2. Build and save Rewrite/Coaching Matcher
    # We will compute the TF-IDF matrix for the social dataset to perform fast similarity searches
    print("[Training Pipeline] Fitting Rewrite/Coaching Matcher...")
    vectorizer = TfidfVectorizer(stop_words='english', ngram_range=(1, 2))
    corpus = [build_rewrite_search_text(item) for item in social_data]
    tfidf_matrix = vectorizer.fit_transform(corpus)
    
    rewrite_matcher = {
        "vectorizer": vectorizer,
        "tfidf_matrix": tfidf_matrix,
        "search_texts": corpus,
        "social_data": social_data
    }
    
    matcher_path = os.path.join(models_dir, "rewrite_matcher.pkl")
    joblib.dump(rewrite_matcher, matcher_path)
    print(f"[Training Pipeline] Rewrite matcher saved to {matcher_path}")
    print("[Training Pipeline] Training complete!")

if __name__ == "__main__":
    train_and_save()
