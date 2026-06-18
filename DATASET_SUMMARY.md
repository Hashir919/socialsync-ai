# Dataset Summary

All datasets have been successfully downloaded from real public sources. No placeholder datasets have been generated.

---

## 1. GoEmotions
*   **Status**: SUCCESS
*   **Download Source**: Google Cloud Storage public URLs (`goemotions_1.csv`, `goemotions_2.csv`, `goemotions_3.csv`)
*   **Train Records**: 147,857
*   **Validation Records**: 31,684
*   **Test Records**: 31,684
*   **Total Records**: 211,225
*   **Labels/Classes**: 28 emotions (multi-label)
*   **File Locations**: 
    *   [goemotions_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/goemotions/goemotions_train.jsonl)
    *   [goemotions_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/goemotions/goemotions_validation.jsonl)
    *   [goemotions_test.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/goemotions/goemotions_test.jsonl)

---

## 2. DailyDialog
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via script-less Parquet version `DeepPavlov/daily_dialog`
*   **Train Records**: 87,170
*   **Validation Records**: 8,069
*   **Test Records**: 7,740
*   **Total Records**: 102,979
*   **Labels/Classes**: Dialogue acts (inform, question, directive, commissive) and emotions (anger, disgust, fear, happiness, sadness, surprise, neutral)
*   **File Locations**:
    *   [dailydialog_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/dailydialog/dailydialog_train.jsonl)
    *   [dailydialog_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/dailydialog/dailydialog_validation.jsonl)
    *   [dailydialog_test.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/dailydialog/dailydialog_test.jsonl)

---

## 3. PersonaChat
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via script-less Parquet version `AlekseyKorshuk/persona-chat`
*   **Train Records**: 17,878
*   **Validation Records**: 1,000
*   **Test Records**: 0
*   **Total Records**: 18,878
*   **Labels/Classes**: Persona descriptions and multi-turn dialogue utterances
*   **File Locations**:
    *   [personachat_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/personachat/personachat_train.jsonl)
    *   [personachat_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/personachat/personachat_validation.jsonl)

---

## 4. EmotionLines (MELD)
*   **Status**: SUCCESS
*   **Download Source**: Direct GitHub CSV files from the `declare-lab/MELD` repository
*   **Train Records**: 9,989
*   **Validation Records**: 1,109
*   **Test Records**: 2,610
*   **Total Records**: 13,708
*   **Labels/Classes**: 7 emotions (anger, disgust, sadness, joy, neutral, surprise, fear)
*   **File Locations**:
    *   [emotionlines_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/emotionlines/emotionlines_train.jsonl)
    *   [emotionlines_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/emotionlines/emotionlines_validation.jsonl)
    *   [emotionlines_test.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/emotionlines/emotionlines_test.jsonl)

---

## 5. Cornell Movie Dialogs
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via script-less Parquet version `spawn99/CornellMovieDialogCorpus`
*   **Total Records**: 304,713
*   **Labels/Classes**: Raw movie utterances with speaker/character name, movie, and character metadata
*   **File Locations**:
    *   [cornell_movie_lines.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/cornell/cornell_movie_lines.jsonl)
