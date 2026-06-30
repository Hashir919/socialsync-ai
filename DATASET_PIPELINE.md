# SocialSync AI Dataset Pipeline & Model Preparation

This document outlines the dataset preparation, preprocessing pipelines, training specifications, and inference engines configured for the SocialSync AI system.

## 1. Dataset Sources & Purpose

We support five standard NLP datasets to train and integrate social-coaching models:

- **GoEmotions**: Used to train the **Emotion Model** (DistilBERT) for multi-label emotion recognition (anxiety, anger, joy, etc.).
- **DailyDialog**: Used to support **Conversation Understanding** and context-aware responses (e.g., matching daily chat structures).
- **PersonaChat**: Used for **Practice Coaches** to dynamically generate personalized responses reflecting distinct persona histories.
- **EmotionLines**: Used to refine multi-turn emotional dialogue flow tracking.
- **Cornell Movie Dialogs**: Used to learn general conversational flow, tone variations, and paraphrasing styles.

---

## 2. Preprocessing Flow

All raw downloaders save dataset splits as JSON Lines (`.jsonl`) under `datasets/raw/`. The preprocessing pipeline in `scripts/preprocess.py` processes these datasets:

1. **Text Cleaning**: Cleans HTML tags, normalizes whitespace/Unicode characters.
2. **Deduplication**: Filters out duplicate text records using hashing.
3. **Splitting**: Automatically splits the cleaned dataset into train (80%), validation (10%), and test (10%) sets.
4. **Target Structure**: Saves splits under `datasets/processed/<dataset_name>/{train,val,test}.jsonl`.

---

## 3. Custom SocialSync Dataset

We have compiled `socialsync_dataset.json` containing **100+ starter examples** targeting common communication challenges:
- **Awkward → Improved**
- **Anxious → Confident**
- **Dry → Engaging**

Each example includes:
- `original_message`
- `improved_message`
- `context`
- `emotion`
- `anxiety_score`

This dataset serves as the seed for training the T5 paraphraser rewrite engine and is leveraged for semantic matching fallbacks.

---

## 4. Model Pipeline & Integration

The backend system is designed to use actual NLP models via the Hugging Face `transformers` library:

- **Emotion Model**: `distilbert-base-uncased-emotion` for predicting state (Fear, Joy, Anger, Neutral) and estimating anxiety scores.
- **Paraphrase Rewrite Engine**: `google-t5/t5-small` to transform anxious/awkward sentences into confident/engaging variants.
- **Practice Coach (Response Generation)**: `microsoft/DialoGPT-small` to dynamically generate responsive chat replies.
- **Whisper Integration**: Ready to process and transcribe audio files via Whisper's Speech-to-Text model.

### Smart Semantic Fallback
If the heavy transformers library is not installed or the models are not yet cached, the pipeline automatically falls back to an intelligent **TF-IDF + Cosine Similarity semantic search retriever** powered by our unique `socialsync_dataset.json`, avoiding generic, repetitive responses.

---

## 5. Execution Scripts

Run the pipeline using these python commands from the project root:

- **Generate Custom Dataset**:
  ```bash
  python scripts/generate_custom_dataset.py
  ```
- **Download Datasets**:
  ```bash
  python scripts/download_goemotions.py
  python scripts/download_dailydialog.py
  python scripts/download_personachat.py
  python scripts/download_emotionlines.py
  python scripts/download_cornell.py
  ```
- **Preprocess Datasets (Basic & Unified Schema conversion)**:
  ```bash
  # Preprocesses basic datasets
  python scripts/preprocess.py
  
  # Maps datasets into the unified dialogue schema
  python scripts/unify_datasets.py
  ```
- **Inference Pipeline & Backend**:
  ```bash
  # Runs the backend with the new NLP-enabled WebSocket handlers
  python backend/main.py
  ```
