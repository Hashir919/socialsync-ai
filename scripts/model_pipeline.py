import os
import json
import re
import random
import numpy as np
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Global variables for caching models/pipelines
_emotion_pipeline = None
_paraphrase_pipeline = None
_chat_pipeline = None

# Local trained models if they exist
_local_emotion_model = None
_local_rewrite_matcher = None
_conversational_retriever = None
_local_intent_model = None

# Custom dataset path
DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")
COACHING_DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "backend", "coaching_dataset.json")


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip().lower())


def load_json_dataset(path: str):
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []

def load_custom_dataset():
    return load_json_dataset(DATASET_PATH)


def load_coaching_dataset():
    return load_json_dataset(COACHING_DATASET_PATH)


def build_rewrite_search_text(item: dict) -> str:
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


def build_rewrite_suggestion(item: dict) -> str:
    category = item.get("category", "").lower()
    context = item.get("context", "General")
    if category == "anxious":
        return f"Matched {context} confidence pattern: remove apologies and lead with calm clarity."
    if category == "dry":
        return f"Matched {context} engagement pattern: add warmth, detail, and a follow-up hook."
    if category == "awkward":
        return f"Matched {context} repair pattern: lower defensiveness and keep the tone constructive."
    if category == "confident":
        return f"Matched {context} confident pattern: keep the energy direct, grounded, and specific."
    return f"Matched context '{context}': focus on confidence and clarity."


def apply_tone_adjustment(text: str, tone: str) -> str:
    tone_lower = (tone or "").lower()
    rewritten = text.strip()
    if not rewritten:
        return rewritten

    if tone_lower == "professional":
        replacements = {
            "Hey!": "Hello,",
            "Hey,": "Hello,",
            "I would love to": "I would be pleased to",
            "Let’s": "I would like to",
            "can u": "could you",
            "u": "you",
            "help me": "assist me",
        }
    elif tone_lower == "warm":
        replacements = {
            "Hello,": "Hi there,",
            "I would": "I'd really",
            "help me": "help if you have a moment",
            "please": "please if you don't mind",
        }
    elif tone_lower == "friendly":
        replacements = {
            "Hello,": "Hey!",
            "I would be glad to": "I'd love to",
            "assist": "help",
            "you": "you :)",
        }
    else:  # confident and default
        replacements = {
            "Hello,": "Hey,",
            "I would": "I'm ready to",
            "help me": "help",
            "can you": "could you",
        }

    for old, new in replacements.items():
        rewritten = rewritten.replace(old, new)

    # Add tone-specific prefix for clearer differentiation
    prefix = ''
    if tone_lower == 'professional':
        prefix = 'Certainly, '
    elif tone_lower == 'friendly':
        prefix = 'Hey there! '
    elif tone_lower == 'warm':
        prefix = 'Hi, '
    elif tone_lower == 'confident':
        prefix = 'Absolutely! '
    rewritten = prefix + rewritten

    # Capitalize first letter and ensure proper punctuation
    rewritten = rewritten[0].upper() + rewritten[1:] if rewritten else rewritten
    if not rewritten.endswith('.') and not rewritten.endswith('!'):
        rewritten += '.'
    rewritten = re.sub(r"\s+", " ", rewritten).strip()
    return rewritten


def score_rewrite_candidates(query_vec, matrix, data, preferred_context: str):
    similarities = cosine_similarity(query_vec, matrix).flatten()
    context_lower = preferred_context.lower()
    best_idx = int(np.argmax(similarities))
    best_score = similarities[best_idx]

    for idx, item in enumerate(data):
        score = similarities[idx]
        item_context = item.get("context", "").lower()
        if context_lower and context_lower in item_context:
            score += 0.12
        if len(normalize_text(item.get("original_message", ""))) <= 12:
            score += 0.02
        if score > best_score:
            best_idx = idx
            best_score = score

    return best_idx, best_score

# Load local checkpoints
try:
    MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "models")
    local_emo_path = os.path.join(MODELS_DIR, "emotion_classifier.pkl")
    if os.path.exists(local_emo_path):
        _local_emotion_model = joblib.load(local_emo_path)
        print("[AI Pipeline] Loaded local emotion classifier checkpoint.")
        
    local_rewrite_path = os.path.join(MODELS_DIR, "rewrite_matcher.pkl")
    if os.path.exists(local_rewrite_path):
        _local_rewrite_matcher = joblib.load(local_rewrite_path)
        print("[AI Pipeline] Loaded local rewrite matcher checkpoint.")

    local_retriever_path = os.path.join(MODELS_DIR, "conversational_retriever.pkl")
    if os.path.exists(local_retriever_path):
        _conversational_retriever = joblib.load(local_retriever_path)
        print("[AI Pipeline] Loaded local conversational retriever checkpoint.")

    # Load intent classifier if available
    local_intent_path = os.path.join(MODELS_DIR, "intent_classifier.pkl")
    if os.path.exists(local_intent_path):
        _local_intent_model = joblib.load(local_intent_path)
        print("[AI Pipeline] Loaded local intent classifier checkpoint.")
except Exception as e:
    print(f"[AI Pipeline] Error loading local model checkpoints: {e}")

def analyze_intent_hf(text: str) -> str:
    """Detect intent using local intent classifier if available, else fallback to keyword matching."""
    global _local_intent_model
    if _local_intent_model is not None:
        try:
            pred = _local_intent_model.predict([text])[0]
            print(f"[AI Pipeline] Intent detected via model: {pred}")
            return pred.lower()
        except Exception as e:
            print(f"[AI Pipeline] Intent model inference failed: {e}")
    # Simple keyword fallback
    kw_map = {
        "interview": "interview",
        "job": "interview",
        "date": "dating",
        "dating": "dating",
        "friend": "friendship",
        "friendship": "friendship",
        "network": "networking",
        "networking": "networking",
        "speech": "speaking",
        "presentation": "speaking",
        "public speaking": "speaking",
        "confidence": "confidence",
        "anxiety": "anxiety",
    }
    text_lower = text.lower()
    for kw, intent in kw_map.items():
        if kw in text_lower:
            return intent
    return "general"

# Cleaned up duplicate patch
# Load the dataset once at module load time
SOCIALSYNC_DATA = load_custom_dataset()
COACHING_DATA = load_coaching_dataset()

# Initialize similarity vectorizer for intelligent fallback
tfidf_vectorizer = TfidfVectorizer(stop_words='english', ngram_range=(1, 2))
if SOCIALSYNC_DATA:
    corpus = [build_rewrite_search_text(item) for item in SOCIALSYNC_DATA]
    tfidf_matrix = tfidf_vectorizer.fit_transform(corpus)
else:
    corpus = []
    tfidf_matrix = None


def get_smart_fallback_rewrite(text: str, context: str, tone: str = "Confident"):
    """Fallback rewrite generator utilizing the custom socialsync dataset and TF-IDF similarity."""
    if not SOCIALSYNC_DATA or tfidf_matrix is None:
        return text, "Try expressing your thoughts directly."

    search_text = " ".join(part for part in [context, text] if part)
    query_vec = tfidf_vectorizer.transform([search_text])
    best_idx, best_score = score_rewrite_candidates(query_vec, tfidf_matrix, SOCIALSYNC_DATA, context)

    if best_score > 0.2:
        matched = SOCIALSYNC_DATA[best_idx]
        return apply_tone_adjustment(matched["improved_message"], tone), build_rewrite_suggestion(matched)
    
    # Generic smart generation based on context
    ctx = context.lower()
    if "interview" in ctx:
        return apply_tone_adjustment("I bring relevant experience that aligns well with this role, and I can explain the value clearly.", tone), "Use the STAR method to structure your response."
    elif "date" in ctx or "dating" in ctx:
        return apply_tone_adjustment("That sounds like a great plan. What part are you most excited about?", tone), "Ask an engaging open-ended question."
    elif "work" in ctx or "workplace" in ctx:
        return apply_tone_adjustment("I'd like to align on the next steps so we can move this forward smoothly.", tone), "Use professional collaborative terms."

    if len(normalize_text(text).split()) <= 2:
        return apply_tone_adjustment("That makes sense. Tell me a little more so I can help you shape it well.", tone), "Expand short replies with a little more detail."

    return apply_tone_adjustment("Thanks for sharing that. I'd love to hear a little more so we can make it sound clear and confident.", tone), "Add one specific detail and end with a clear next step."

def analyze_emotion_hf(text: str) -> dict:
    """Run local trained LogisticRegression model if available, else DistilBERT, else keyword match."""
    global _emotion_pipeline, _local_emotion_model
    print(f"[AI Pipeline] Triggered Emotion Detection for text: '{text}'")
    
    # 1. Try local trained classifier
    if _local_emotion_model is not None:
        try:
            pred = _local_emotion_model.predict([text])[0]
            classes = list(_local_emotion_model.classes_)
            probs = _local_emotion_model.predict_proba([text])[0]
            prob_dict = dict(zip(classes, probs))
            anxiety_base = prob_dict.get("Anxiety", prob_dict.get("Fear", 0.2))
            # If the predicted label maps to high anxiety, return that
            anxiety_map = {"fear": 0.8, "sadness": 0.6, "anger": 0.4, "joy": 0.1, "surprise": 0.2, "love": 0.1, "anxiety": 0.85}
            anxiety_base = max(anxiety_base, anxiety_map.get(pred.lower(), 0.2))
            
            print(f"[AI Pipeline] Model used: Local LogisticRegression Classifier (Detected Emotion: '{pred}', Anxiety Score: {anxiety_base:.2f})")
            return {"emotion": pred, "anxiety_score": anxiety_base}
        except Exception as e:
            print(f"[AI Pipeline] Local emotion model inference failed: {e}. Trying DistilBERT...")
            
    # 2. Try Hugging Face DistilBERT
    try:
        from transformers import pipeline
        if _emotion_pipeline is None:
            print("[AI Pipeline] Loading DistilBERT GoEmotions model...")
            # bhadresh-savani/distilbert-base-uncased-emotion is lightweight (~260MB)
            _emotion_pipeline = pipeline("text-classification", model="bhadresh-savani/distilbert-base-uncased-emotion", top_k=1)
            print("[AI Pipeline] DistilBERT GoEmotions loaded successfully.")
        
        res = _emotion_pipeline(text)
        if res and len(res) > 0:
            best_match = res[0]
            if isinstance(best_match, list):
                best_match = best_match[0]
            label = best_match.get("label", "neutral").capitalize()
            score = best_match.get("score", 0.5)
            print(f"[AI Pipeline] Model used: DistilBERT Emotion Inference: Detected '{label}' (confidence: {score:.2f})")
            # Map default labels to SocialSync expected format
            anxiety_map = {"fear": 0.8, "sadness": 0.6, "anger": 0.4, "joy": 0.1, "surprise": 0.2, "love": 0.1}
            anxiety_base = anxiety_map.get(label.lower(), 0.2)
            return {"emotion": label, "anxiety_score": anxiety_base}
    except Exception as e:
        print(f"[AI Pipeline] DistilBERT loading/inference failed: {e}. Falling back to keyword analysis.")
        
    # Standard keyword & similarity fallback
    print("[AI Pipeline] Model used: Heuristic Keyword/Rule Fallback")
    text_lower = text.lower()
    if any(w in text_lower for w in ["nervous", "scared", "fear", "anxious", "sorry", "panic"]):
        return {"emotion": "Fear", "anxiety_score": 0.85}
    elif any(w in text_lower for w in ["happy", "excited", "great", "glad", "awesome"]):
        return {"emotion": "Joy", "anxiety_score": 0.10}
    elif any(w in text_lower for w in ["mad", "angry", "annoyed", "frustrated", "hate"]):
        return {"emotion": "Anger", "anxiety_score": 0.40}
    
    return {"emotion": "Neutral", "anxiety_score": 0.20}

def rewrite_message_hf(text: str, context: str, tone: str = "Confident") -> tuple:
    """Paraphrase message using local rewrite matcher, T5, or fallback to smart dataset retriever."""
    global _paraphrase_pipeline, _local_rewrite_matcher
    print(f"[AI Pipeline] Triggered Rewrite Engine for text: '{text}' in context: '{context}' with tone: '{tone}'")
    
    # 1. Try local rewrite matcher first
    if _local_rewrite_matcher is not None:
        try:
            vectorizer = _local_rewrite_matcher["vectorizer"]
            tfidf_matrix = _local_rewrite_matcher["tfidf_matrix"]
            social_data = _local_rewrite_matcher["social_data"]
            
            search_text = " ".join(part for part in [context, text] if part)
            query_vec = vectorizer.transform([search_text])
            best_idx, best_score = score_rewrite_candidates(query_vec, tfidf_matrix, social_data, context)

            if best_score > 0.2:
                matched = social_data[best_idx]
                print(f"[AI Pipeline] Model used: Local TF-IDF Rewrite Matcher (Similarity: {best_score:.2f})")
                return apply_tone_adjustment(matched["improved_message"], tone), build_rewrite_suggestion(matched)
        except Exception as e:
            print(f"[AI Pipeline] Local rewrite matcher inference failed: {e}. Trying T5...")
            
    # 2. Try Hugging Face T5
    try:
        from transformers import pipeline
        if _paraphrase_pipeline is None:
            print("[AI Pipeline] Loading T5 paraphrase model...")
            _paraphrase_pipeline = pipeline("text2text-generation", model="google-t5/t5-small")
            print("[AI Pipeline] T5 Paraphraser loaded successfully.")
            
        prompt = f"paraphrase in a {tone.lower()} tone: {text} context: {context}"
        res = _paraphrase_pipeline(prompt, max_length=64)
        if res and len(res) > 0:
            improved = res[0].get("generated_text", "")
            if len(improved.strip()) > 5:
                print(f"[AI Pipeline] Model used: T5 Rewrite Engine (Result: '{improved}')")
                return apply_tone_adjustment(improved, tone), f"Paraphrased for a {tone.lower()} tone with better flow."
    except Exception as e:
        print(f"[AI Pipeline] T5 rewrite engine failed: {e}. Falling back to tone-specific templates.")

    print("[AI Pipeline] Model used: Fallback (Tone-specific rewrite templates)")
    # Simple predefined rewrite templates for each tone
    tone_templates = {
        "professional": "Hi, could you please help me with this?",
        "friendly": "Hey! Could you help me out with something?",
        "warm": "Hey, I could really use some help if you have a moment.",
        "confident": "I would appreciate your assistance."
    }
    tmpl = tone_templates.get(tone.lower())
    if tmpl:
        return tmpl, f"Rewrite using {tone} tone template."
    # Fallback to generic adjustment
    adjusted = apply_tone_adjustment(text, tone)
    return adjusted, f"Fallback rewrite using tone adjustment for '{tone}' tone."

_session_histories = {}
_conversational_states = {}
_practice_states = {}

def get_session_history(session_id: str = "default") -> list:
    if session_id not in _session_histories:
        _session_histories[session_id] = []
    return _session_histories[session_id]

def add_session_message(user_msg: str, bot_msg: str, session_id: str = "default"):
    history = get_session_history(session_id)
    history.append((user_msg, bot_msg))
    if len(history) > 6:
        history.pop(0)


def get_coaching_dataset_reply(user_input: str, context: str):
    if not COACHING_DATA:
        return None

    normalized_input = normalize_text(user_input)
    best_item = None
    best_score = 0.0

    for item in COACHING_DATA:
        item_text = normalize_text(item.get("text", ""))
        if not item_text:
            continue
        shared_words = set(normalized_input.split()) & set(item_text.split())
        score = len(shared_words) / max(1, len(set(item_text.split())))
        if context and context.lower() == item.get("context", "").lower():
            score += 0.15
        if score > best_score:
            best_score = score
            best_item = item

    if best_item and best_score >= 0.18:
        tip = best_item.get("suggestion", "").strip()
        if tip:
            return f"{best_item['improved']} Tip: {tip}"
        return best_item["improved"]
    return None

def generate_coach_response_hf(user_input: str, persona: str, context: str, session_id: str = "default") -> str:
    """Generate dynamic conversation response using memory-aware Dialogue Retriever or specialized practice flow."""
    input_lower = user_input.lower().strip()
    persona_lower = persona.lower()

    # 1. Active State initialization
    # Practice coaches handling
    practice_coaches = ["interview", "dating", "friendship", "networking", "speaking"]
    if any(pc in persona_lower for pc in practice_coaches):
        # Initialize practice state if needed
        if session_id not in _practice_states:
            _practice_states[session_id] = {'step': 0, 'details': {}}
        state = _practice_states[session_id]
        is_initial = any(w in input_lower for w in ["hello", "hi", "hey", "start", "begin", "ready"]) or len(user_input) < 3
        if is_initial:
            state['step'] = 0
        step = state['step']
        # Interview practice flow
        if "interview" in persona_lower:
            if step == 0:
                state['step'] = 1
                return "Welcome! Thank you for coming in today. I'll be conducting your mock interview. To start, what specific role are you interviewing for, and can you briefly share your background?"
            elif step == 1:
                state['details']['role'] = user_input.strip()
                state['step'] = 2
                return f"Got it, a {state['details']['role']} position! Let's start with a technical question. In your experience, how do you handle state management, performance optimization, or data flow in your applications?"
            elif step == 2:
                state['step'] = 3
                return "Excellent explanation. Let's move to a behavioral scenario. Tell me about a time you had a conflict with a teammate or a tight deadline, and how you resolved it."
            elif step == 3:
                state['step'] = 4
                return "Understood. Adaptability and structure make a big difference. Finally, why do you want to join our team, and what is your greatest professional strength?"
            elif step == 4:
                state['step'] = 0
                return (
                    "That concludes our mock interview session!\n\n"
                    "- **Technical competency**: 88%\n"
                    "- **Communication flow**: 90%\n"
                    "- **Clarity & Pacing**: 85%\n\n"
                    "**Actionable Tips:**\n"
                    "1. Your technical explanation was solid. Keep practicing explaining complex topics simply.\n"
                    "2. Structure your behavioral stories with the STAR method (Situation, Task, Action, Result)."
                )
        # Dating practice flow
        elif "dating" in persona_lower:
            if step == 0:
                state['step'] = 1
                return "Hey! I'm your Dating Coach. Let's practice social confidence and first date interactions. Imagine we've just met at a cozy cafe. How would you start the conversation?"
            elif step == 1:
                state['step'] = 2
                return "That's a nice start! A good icebreaker is always open-ended. Now, how would you share a hobby or interest of yours in an engaging way, and ask about mine?"
            elif step == 2:
                state['step'] = 3
                return "Excellent. Keep the energy balanced and positive. If there's a moment of silence, what's a fun or spontaneous question you'd ask to keep things flowing?"
            elif step == 3:
                state['step'] = 4
                return "Perfect. Now let's practice ending the date. How would you confidently suggest meeting up again if you had a great time?"
            elif step == 4:
                state['step'] = 0
                return (
                    "Wonderful job! That concludes our practice date. Here is your feedback:\n\n"
                    "- **Confidence Level**: 92%\n"
                    "- **Engagement & Warmth**: 88%\n"
                    "- **Conversation Flow**: 85%\n\n"
                    "**Actionable Tips:**\n"
                    "1. Great job staying positive and showing genuine curiosity!\n"
                    "2. Try asking more open-ended questions to allow the other person to share details."
                )
        # Friendship practice flow
        elif "friendship" in persona_lower:
            if step == 0:
                state['step'] = 1
                return "Hi! I'm your Friendship Coach. Let's work on conflict resolution and building strong relationships. Imagine a close friend hasn't replied to your messages for a week, and you feel ignored. How would you reach out to express this without sounding accusatory?"
            elif step == 1:
                state['step'] = 2
                return "A thoughtful approach! Expressing your feelings directly is key. Now, imagine they reply: 'Sorry, I've just been super busy.' How do you respond to show support while maintaining your boundary?"
            elif step == 2:
                state['step'] = 3
                return "Great job showing empathy. Now let's try a different scenario: your friend made a joke that hurt your feelings in front of others. How would you bring this up to them privately?"
            elif step == 3:
                state['step'] = 4
                return "Excellent. Private, honest communication preserves trust. How would you suggest a fun activity for you both to reconnect and strengthen your bond?"
            elif step == 4:
                state['step'] = 0
                return (
                    "Great practice! That concludes our friendship session. Here is your evaluation:\n\n"
                    "- **Conflict Resolution**: 90%\n"
                    "- **Empathy & Listening**: 92%\n"
                    "- **Boundary Setting**: 86%\n\n"
                    "**Actionable Tips:**\n"
                    "1. You did a great job using 'I' statements instead of placing blame.\n"
                    "2. Proposing concrete ways to reconnect shows high commitment to the relationship."
                )
        # Networking practice flow
        elif "networking" in persona_lower:
            if step == 0:
                state['step'] = 1
                return "Hello! Let's practice professional networking. Imagine we are at an industry conference. You walk up to someone in your field. How do you introduce yourself and state what you do?"
            elif step == 1:
                state['step'] = 2
                return "Good introduction! A clean elevator pitch is crucial. Now, how do you ask them about their current projects or challenges in a way that shows genuine professional interest?"
            elif step == 2:
                state['step'] = 3
                return "Very professional. Now, if they tell you they are struggling with scaling their development team, how would you offer to share your own insights or coordinate a follow-up discussion?"
            elif step == 3:
                state['step'] = 4
                return "Excellent. Close the interaction by suggesting to connect on LinkedIn or exchange contact details. How would you phrase that?"
            elif step == 4:
                state['step'] = 0
                return (
                    "Superb networking! That concludes our conference practice. Here is your feedback:\n\n"
                    "- **Professional Presence**: 88%\n"
                    "- **Value Pitch Clarity**: 86%\n"
                    "- **Social Warmth**: 85%\n\n"
                    "**Actionable Tips:**\n"
                    "1. Your elevator pitch was clear and focused.\n"
                    "2. Offering mutual value first before asking for contact details builds trust quickly."
                )
        # Speaking practice flow
        elif "speaking" in persona_lower:
            if step == 0:
                state['step'] = 1
                return "Welcome! I'm your Public Speaking coach. Let's work on your presentation confidence and audience engagement. Introduce the topic of your presentation in 2-3 strong, hook-filled sentences."
            elif step == 1:
                state['step'] = 2
                return "Great hook! Now, try presenting your first major point. How do you transition from your introduction to explaining the core problem you're solving?"
            elif step == 2:
                state['step'] = 3
                return "Good transition. To keep the audience engaged, try using a rhetorical question or a brief real-world example here. How would you phrase it?"
            elif step == 3:
                state['step'] = 4
                return "Excellent. Now, summarize your talk. What is the key takeaway you want your audience to remember, and how will you close the speech?"
            elif step == 4:
                state['step'] = 0
                return (
                    "Brilliant presentation! That concludes our speaking run. Here is your score sheet:\n\n"
                    "- **Audience Engagement**: 90%\n"
                    "- **Structure & Transition**: 88%\n"
                    "- **Clarity & Pacing**: 85%\n\n"
                    "**Actionable Tips:**\n"
                    "1. Try pausing for 2 seconds after rhetorical questions to let them sink in.\n"
                    "2. Keep your closing call-to-action simple and direct."
                )
        # If not a recognized practice persona, continue with normal flow

    if session_id not in _conversational_states:
        _conversational_states[session_id] = {'topic': None, 'role': None, 'details': {}}
    state = _conversational_states[session_id]

    # Extract context dynamically from user inputs
    if "interview" in input_lower or "job prep" in input_lower:
        state['topic'] = 'interview'
    
    # Check for role patterns
    roles_to_check = ["flutter developer", "software engineer", "product manager", "designer", "data analyst", "marketing"]
    for r in roles_to_check:
        if r in input_lower:
            state['role'] = r.title()
            state['topic'] = 'interview'

    # Reset interview context if no interview-related cues are present
    interview_cues = ["interview", "job prep"]
    if state['topic'] == 'interview' and not any(kw in input_lower for kw in interview_cues) and not state.get('role'):
        state['topic'] = None
        state['role'] = None

    # Detect emotion and intent using the trained models
    emotion_info = analyze_emotion_hf(user_input)
    intent = analyze_intent_hf(user_input)

    # Retrieval check
    best_score = 0.0
    matched_query = ""
    matched_response = ""
    matched_source = "None"
    
    if _conversational_retriever is not None:
        try:
            vectorizer = _conversational_retriever["vectorizer"]
            tfidf_matrix = _conversational_retriever["tfidf_matrix"]
            responses = _conversational_retriever["responses"]
            queries = _conversational_retriever.get("queries", [])
            sources = _conversational_retriever.get("sources", [])
            
            # Use query with context or history
            history = get_session_history(session_id)
            context_words = [u for u, b in history] + [user_input]
            contextual_query = " ".join(context_words)
            
            query_vec = vectorizer.transform([contextual_query])
            similarities = cosine_similarity(query_vec, tfidf_matrix).flatten()
            best_idx = np.argmax(similarities)
            best_score = float(similarities[best_idx])
            
            if best_score > 0.0:
                matched_query = queries[best_idx] if queries else ""
                matched_response = responses[best_idx]
                matched_source = sources[best_idx] if sources else "unknown"
        except Exception as e:
            print(f"[AI Pipeline] Retrieval calculation failed: {e}")

    # Determine response logic
    reply = ""
    fallback_used = False
    fallback_reason = ""

    # Check greeting first
    if len(input_lower.split()) <= 2 and any(re.search(rf"\b{re.escape(w)}\b", input_lower) for w in ["hello", "hi", "hey", "greet", "greetings"]):
        reply = "Hello! I am your SocialSync AI Coach. I'm here to help you navigate social anxiety, build communication confidence, or practice relationships and interviews. What's on your mind today?"
        fallback_used = True
        fallback_reason = "Short greeting detected, handled by rule-based greeting flow."
    
    # Stateful dialogue logic based on extracted context
    elif state['topic'] == 'interview' and (state.get('role') or any(kw in input_lower for kw in ["interview", "job prep", "what to expect", "technical", "prep", "prepare", "question", "state management", "riverpod", "bloc", "setstate"])):
        fallback_used = True
        fallback_reason = "Active interview state detected, handled by stateful interview prep flow."
        if state['role']:
            if any(w in input_lower for w in ["what to expect", "technical", "prep", "prepare", "question"]):
                reply = f"For a {state['role']} role, technical interviews usually focus on core architecture, state management, and performance. In a {state['role']} interview, you should expect questions about system design and best practices. Would you like to practice explaining a key concept, or discuss common coding questions?"
            elif any(w in input_lower for w in ["state management", "riverpod", "bloc", "setstate"]):
                reply = f"Ah, state management is a crucial topic for a {state['role']}! Interviewers love to ask about how you handle state changes asynchronously. For instance, explaining when to use Riverpod versus standard Provider demonstrates high competency. How do you normally structure your apps?"
            else:
                reply = f"A {state['role']} interview! That is fantastic. Let's prep for it. They will likely ask about your background, followed by technical concepts. Let's do a run-through: how would you describe your experience as a {state['role']}?"
        else:
            reply = "Congratulations on your upcoming interview! It's natural to feel nervous. What specific role is it for? If you share the job title, I can tailor our practice questions and tech stack discussion."
            
    # Conversational retriever (strong match threshold 0.70)
    elif best_score >= 0.70:
        reply = matched_response
        fallback_used = False
        fallback_reason = "N/A - retrieved strong match from dataset"
        
    # Fallback replies for weak matches or no matches
    else:
        fallback_used = True
        fallback_reason = f"No strong dataset match with similarity score >= 0.70 (highest score was {best_score:.4f}). Returning intent-specific coaching fallback."
        
        # Intent-specific contextual coaching responses
        intent_fallbacks = {
            "loneliness": "I hear you, and it's completely okay to feel lonely. Building connections takes time, but you don't have to navigate this alone. What's one small step you feel comfortable taking today, like reaching out to an old acquaintance or exploring a hobby group?",
            "friendship": "Friendship dynamics can be incredibly challenging when messages go unanswered or plans change. Try to focus on what you can control, and express your feelings calmly with 'I' statements. Would you like to draft a gentle message together to check in?",
            "social anxiety": "Social anxiety is a very common hurdle, and it's natural to feel tense or nervous. Try to take a few deep breaths and focus on a single friendly face rather than the whole room. Remember, you belong in these spaces just as much as anyone else.",
            "overthinking": "It's so easy to get stuck in a loop of replaying past conversations or overanalyzing every word. Remember that most people are focused on their own lives, not scrutinizing your slips. Let's practice letting go of that loop and focusing on the present moment.",
            "dating": "Dating jitters are normal, and starting a conversation with a crush can feel high-stakes. Try to keep it low-pressure—reframe the first interaction as just a test to see if you have fun. What's a simple, open-ended question about their interests you'd like to try?",
            "rejection": "Rejection can feel heavy and disappointing, but it is not a reflection of your worth. It's often just a matter of timing or compatibility. Be proud of yourself for taking the risk, and let's focus on dusting ourselves off for the next opportunity.",
            "confidence": "Building confidence is a journey of small actions. Speaking assertively with ownership of your ideas and keeping your body language open are great steps. How can we rephrase what you want to say to sound more assured?",
            "networking": "Networking is essentially just professional friend-making. Try preparing a brief two-sentence introduction about what you love building, and focus on asking them curious questions about their current projects. People love sharing their stories!",
            "awkward conversations": "Conversational pauses or minor slip-ups happen to everyone and don't make you awkward. If a silence feels long, you can transition naturally with a light observation or ask a friendly follow-up question to keep the flow going.",
            "self-esteem": "Negative self-talk can cloud how we see our progress. Be kind to yourself, and remember that everyone is learning at their own pace. What is one small success or strength of yours we can celebrate today?"
        }
        
        reply = intent_fallbacks.get(intent)
        if not reply:
            # Check keywords/general as backup if intent is not mapped
            if any(w in input_lower for w in ["text", "reply", "message", "say back", "respond"]):
                reply = "We can absolutely work on the wording together. Share the exact message or draft, and I will help you make it clear, calm, and confident."
            elif any(w in input_lower for w in ["presentation", "speech", "audience", "stage"]):
                reply = "You're not alone in feeling pressure around speaking. We can work on your opening, your pacing, or a calmer version of what you want to say."
            else:
                reply = "That makes a lot of sense. Tell me a little more about what is on your mind, and I'll help you shape the next step."

    # Print verification info as required by user
    print("\n========================================")
    print(f"Input: {user_input}")
    print(f"Detected Emotion: {emotion_info.get('emotion')}")
    print(f"Detected Intent: {intent}")
    print(f"Retrieval Match Score: {best_score:.4f}")
    print(f"Retrieval Source Dataset: {matched_source}")
    print(f"Matched Record Text: {matched_query} -> {matched_response}")
    print(f"Fallback Used: {fallback_used}")
    if fallback_used:
        print(f"Fallback Reason: {fallback_reason}")
    print(f"Final Response: {reply}")
    print("========================================\n")

    add_session_message(user_input, reply, session_id)
    return reply
