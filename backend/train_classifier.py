import json
import pathlib
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.multioutput import MultiOutputClassifier
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
import joblib

# Paths
BASE_DIR = pathlib.Path(__file__).parent
DATA_PATH = BASE_DIR / "coaching_dataset.json"
MODEL_PATH = BASE_DIR / "coach_model.joblib"

def load_dataset(path: pathlib.Path):
    """Load coaching dataset from JSON.

    Expected format: a list of objects with keys:
        - "trigger": user input text
        - "emotion": emotion label
        - "suggestion": coach suggestion label
    """
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    # Convert to parallel lists
    texts = [item["text"] for item in data]
    emotions = [item["emotion"] for item in data]
    suggestions = [item["suggestion"] for item in data]
    return texts, emotions, suggestions

def train_model(texts, emotions, suggestions):
    # Split data
    X_train, X_test, y_emotion_train, y_emotion_test, y_sugg_train, y_sugg_test = train_test_split(
        texts, emotions, suggestions, test_size=0.2, random_state=42
    )
    # Build pipeline with TF‑IDF and multi‑output logistic regression
    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer()),
        (
            "clf",
            MultiOutputClassifier(
                LogisticRegression(max_iter=1000, n_jobs=-1, class_weight="balanced")
            ),
        ),
    ])
    # Fit on training data (both targets together)
    y_train = list(zip(y_emotion_train, y_sugg_train))
    pipeline.fit(X_train, y_train)
    # Evaluate
    y_pred = pipeline.predict(X_test)
    y_emotion_pred, y_sugg_pred = zip(*y_pred)
    print("=== Emotion Classification Report ===")
    print(classification_report(y_emotion_test, y_emotion_pred))
    print("=== Suggestion Classification Report ===")
    print(classification_report(y_sugg_test, y_sugg_pred))
    return pipeline

def main():
    texts, emotions, suggestions = load_dataset(DATA_PATH)
    model = train_model(texts, emotions, suggestions)
    joblib.dump(model, MODEL_PATH)
    print(f"Model saved to {MODEL_PATH}")

if __name__ == "__main__":
    main()
