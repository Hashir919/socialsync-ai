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

---

## 6. UltraChat
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via `HuggingFaceH4/ultrachat_200k`
*   **Train SFT Records**: 207,865
*   **Test SFT Records**: 23,110
*   **Train Gen Records**: 256,032
*   **Test Gen Records**: 28,304
*   **Total Records**: 515,311
*   **Labels/Classes**: Multi-turn conversational instruction/dialogue (prompt, messages with role/content)
*   **File Locations**:
    *   [ultrachat_train_sft.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/ultrachat/ultrachat_train_sft.jsonl) (1,442,046,654 bytes)
    *   [ultrachat_test_sft.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/ultrachat/ultrachat_test_sft.jsonl) (159,694,926 bytes)
    *   [ultrachat_train_gen.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/ultrachat/ultrachat_train_gen.jsonl) (1,393,794,357 bytes)
    *   [ultrachat_test_gen.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/ultrachat/ultrachat_test_gen.jsonl) (153,397,458 bytes)

---

## 7. OpenAssistant/oasst1
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via `OpenAssistant/oasst1`
*   **Train Records**: 84,437
*   **Validation Records**: 4,401
*   **Total Records**: 88,838
*   **Labels/Classes**: message_id, parent_id, user_id, created_date, text, role, lang, review_count, review_result, deleted, rank, synthetic, model_name, detoxify, message_tree_id, tree_state, emojis, labels
*   **File Locations**:
    *   [oasst_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/oasst/oasst_train.jsonl) (137,576,023 bytes)
    *   [oasst_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/oasst/oasst_validation.jsonl) (7,190,207 bytes)

---

## 8. SlimOrca
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via `Open-Orca/SlimOrca`
*   **Train Records**: 517,982
*   **Total Records**: 517,982
*   **Labels/Classes**: conversations
*   **File Locations**:
    *   [slimorca_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/slimorca/slimorca_train.jsonl)

---

## 9. EmpatheticDialogues
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via `empathetic_dialogues` (converted parquet files)
*   **Train Records**: 76,673
*   **Validation Records**: 12,030
*   **Test Records**: 10,943
*   **Total Records**: 99,646
*   **Labels/Classes**: conv_id, utterance_idx, context, prompt, speaker_idx, utterance, selfeval, tags
*   **File Locations**:
    *   [empathetic_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/empathetic_dialogues/empathetic_train.jsonl)
    *   [empathetic_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/empathetic_dialogues/empathetic_validation.jsonl)
    *   [empathetic_test.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/empathetic_dialogues/empathetic_test.jsonl)

---

## 10. Wizard of Wikipedia
*   **Status**: SUCCESS
*   **Download Source**: Hugging Face via `chujiezheng/wizard_of_wikipedia`
*   **Train Records**: 18,430
*   **Validation Records**: 1,948
*   **Test Records**: 1,933
*   **Total Records**: 22,311
*   **Labels/Classes**: post, knowledge, labels, response, topics
*   **File Locations**:
    *   [wizard_train.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/wizard/wizard_train.jsonl)
    *   [wizard_validation.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/wizard/wizard_validation.jsonl)
    *   [wizard_test.jsonl](file:///c:/Users/Invade/Desktop/socialsync-ai/datasets/raw/wizard/wizard_test.jsonl)



