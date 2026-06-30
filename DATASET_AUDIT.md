# Dataset Audit Report

This report presents a detailed audit of the 12 raw datasets collected in the project root under `datasets/raw/`. It contains statistics on records, formats, columns, duplicates, and missing values, defines a unified schema to represent all datasets, and details a mapping plan for conversion.

---

## 1. Dataset Verification & Audit Statistics

Below is the summary of the audited datasets:

| Dataset | Total Records | Format | Columns / Fields | Duplicate % | Missing Values % |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GoEmotions** | 211,225 | JSONL | `labels`, `text` | 27.8708% | 0.00% |
| **DailyDialog** | 102,979 | JSONL | `act_label`, `act_label_text`, `dialog`, `emotion_label`, `emotion_label_text` | 6.8431% | 0.00% |
| **PersonaChat** | 18,878 | JSONL | `personality`, `utterances` | 0.00% | 0.00% |
| **EmotionLines** | 13,708 | JSONL | `emotion`, `speaker`, `utterance` | 5.5880% | 0.00% |
| **Cornell** | 304,713 | JSONL | `characterID`, `characterName`, `lineID`, `movieID`, `utterance` | 0.00% | 0.02% |
| **UltraChat** | 515,311 | JSONL | `messages`, `prompt`, `prompt_id` | 0.00% | ~0.00% |
| **OpenAssistant** | 88,838 | JSONL | `message_id`, `parent_id`, `user_id`, `created_date`, `text`, `role`, `lang`, `review_count`, `review_result`, `deleted`, `rank`, `synthetic`, `model_name`, `detoxify`, `message_tree_id`, `tree_state`, `emojis`, `labels` | 0.00% | 10.26% |
| **EmpatheticDialogues** | 99,646 | JSONL | `context`, `conv_id`, `prompt`, `selfeval`, `speaker_idx`, `tags`, `utterance`, `utterance_idx` | 0.00% | 12.39% |
| **CounselChat** | 2,775 | CSV | `answerText`, `questionID`, `questionLink`, `questionText`, `questionTitle`, `therapistInfo`, `therapistURL`, `topic`, `upvotes`, `views` | 0.00% | 0.59% |
| **Wizard of Wikipedia** | 22,311 | JSONL | `knowledge`, `labels`, `post`, `response`, `topics` | 0.00% | 0.00% |
| **MultiWOZ** | 10,437 | Parquet | `dialogue_id`, `services`, `turns` | 0.00% | 1.33% |
| **SlimOrca** | 517,982 | JSONL | `conversations` | 0.00% | 0.00% |

---

## 2. Unified Schema Definition

To allow training diverse conversational coaching, emotional counseling, and paraphrasing models, we define a unified schema capable of holding single-turn Q&A, multi-turn dialogues, multi-party conversations, speaker labels, and metadata annotations.

```json
{
  "dialogue_id": "string",
  "source_dataset": "string",
  "context": {
    "topic": "string",
    "persona": ["string"],
    "situation": "string",
    "metadata": {}
  },
  "messages": [
    {
      "role": "user | assistant | system | string",
      "text": "string",
      "annotations": {
        "emotion": ["string"],
        "act": "string",
        "intents": ["string"],
        "other": {}
      }
    }
  ]
}
```

---

## 3. Dataset Mapping Plan

### GoEmotions
- **Dialogue ID**: Generate unique ID using UUID or index.
- **Context**: Empty.
- **Messages**: 
  - Turn 1: `role` = "user", `text` = `text`, `annotations.emotion` = list of mapped emotions based on `labels`.

### DailyDialog
- **Dialogue ID**: Generate unique ID.
- **Context**: Empty.
- **Messages**: Iterate over `dialog`. Alternate roles `user` and `assistant`. Annotate each message turn with corresponding `act_label_text` and `emotion_label_text`.

### PersonaChat
- **Dialogue ID**: Generate unique ID.
- **Context**: Set `context.persona` = `personality`.
- **Messages**: Reconstruct conversation turns from the `utterances` history. Map roles based on alternating turns.

### EmotionLines
- **Dialogue ID**: Group by contiguous dialogue blocks or generate unique IDs.
- **Context**: Empty.
- **Messages**: Set `role` = `speaker`, `text` = `utterance`, `annotations.emotion` = `[emotion]`.

### Cornell
- **Dialogue ID**: Group lines by `movieID` or conversation thread if available.
- **Context**: Set `context.metadata.movie_id` = `movieID`.
- **Messages**: Set `role` = `characterName`, `text` = `utterance`.

### UltraChat
- **Dialogue ID**: Set `dialogue_id` = `prompt_id`.
- **Context**: Set `context.situation` = `prompt`.
- **Messages**: Map `messages` array: `role` = `role` (user/assistant), `text` = `content`.

### OpenAssistant
- **Dialogue ID**: Set `dialogue_id` = `message_tree_id`.
- **Context**: Empty.
- **Messages**: Reconstruct conversation tree into linear branches. Map `role` = "user" if `role` is "user", else "assistant", `text` = `text`.

### EmpatheticDialogues
- **Dialogue ID**: Set `dialogue_id` = `conv_id`.
- **Context**: Set `context.situation` = `prompt`, `context.topic` = `context`.
- **Messages**: Group and sort records by `utterance_idx`. Alternate roles based on `speaker_idx`. `text` = `utterance`.

### CounselChat
- **Dialogue ID**: Set `dialogue_id` = `questionID`.
- **Context**: Set `context.topic` = `topic`, `context.situation` = `questionTitle`.
- **Messages**: 
  - Turn 1: `role` = "user", `text` = `questionText`.
  - Turn 2: `role` = "assistant", `text` = `answerText`, `annotations.other` = {"upvotes": `upvotes`, "views": `views`}.

### Wizard of Wikipedia
- **Dialogue ID**: Generate unique ID.
- **Context**: Set `context.topic` = `topics`.
- **Messages**: Set alternating roles for user and wizard. Map `post` to user/wizard history, `response` to wizard response, and include `knowledge` in annotations.

### MultiWOZ
- **Dialogue ID**: Set `dialogue_id` = `dialogue_id`.
- **Context**: Set `context.metadata.services` = `services`.
- **Messages**: Parse nested `turns`. `role` = "user" if `speaker` is 0 else "assistant". `text` = `utterance`.

### SlimOrca
- **Dialogue ID**: Generate unique ID.
- **Context**: Empty.
- **Messages**: Map `conversations` array: `role` = "user" if `from` is "human" else ("system" if `from` is "system" else "assistant"), `text` = `value`.
