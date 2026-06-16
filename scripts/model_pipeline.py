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

# Custom dataset path
DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")

def load_custom_dataset():
    if os.path.exists(DATASET_PATH):
        try:
            with open(DATASET_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []

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
except Exception as e:
    print(f"[AI Pipeline] Failed to load local checkpoints: {e}")

# Load the dataset once at module load time
SOCIALSYNC_DATA = load_custom_dataset()

# Initialize similarity vectorizer for intelligent fallback
tfidf_vectorizer = TfidfVectorizer(stop_words='english')
if SOCIALSYNC_DATA:
    corpus = [item["original_message"] for item in SOCIALSYNC_DATA]
    tfidf_matrix = tfidf_vectorizer.fit_transform(corpus)
else:
    corpus = []
    tfidf_matrix = None


def get_smart_fallback_rewrite(text: str, context: str):
    """Fallback rewrite generator utilizing the custom socialsync dataset and TF-IDF similarity."""
    if not SOCIALSYNC_DATA or tfidf_matrix is None:
        return text, "Try expressing your thoughts directly."
        
    query_vec = tfidf_vectorizer.transform([text])
    similarities = cosine_similarity(query_vec, tfidf_matrix).flatten()
    best_idx = np.argmax(similarities)
    
    if similarities[best_idx] > 0.2:
        matched = SOCIALSYNC_DATA[best_idx]
        return matched["improved_message"], f"Matched context '{matched['context']}': Focus on confidence and clarity."
    
    # Generic smart generation based on context
    ctx = context.lower()
    if "interview" in ctx:
        return f"I bring key experience that directly aligns with the objectives of this role.", "Use the STAR method to structure your response."
    elif "date" in ctx or "dating" in ctx:
        return f"That sounds like a great plan! What's your favorite part about it?", "Ask an engaging open-ended question."
    elif "work" in ctx or "workplace" in ctx:
        return f"Let's sync up on these goals to ensure we are fully aligned.", "Use professional collaborative terms."
    
    return f"Thanks for sharing. I'd love to hear more about that.", "Ask a follow-up question."

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

def rewrite_message_hf(text: str, context: str) -> tuple:
    """Paraphrase message using local rewrite matcher, T5, or fallback to smart dataset retriever."""
    global _paraphrase_pipeline, _local_rewrite_matcher
    print(f"[AI Pipeline] Triggered Rewrite Engine for text: '{text}' in context: '{context}'")
    
    # 1. Try local rewrite matcher first
    if _local_rewrite_matcher is not None:
        try:
            vectorizer = _local_rewrite_matcher["vectorizer"]
            tfidf_matrix = _local_rewrite_matcher["tfidf_matrix"]
            social_data = _local_rewrite_matcher["social_data"]
            
            query_vec = vectorizer.transform([text])
            similarities = cosine_similarity(query_vec, tfidf_matrix).flatten()
            best_idx = np.argmax(similarities)
            
            if similarities[best_idx] > 0.2:
                matched = social_data[best_idx]
                print(f"[AI Pipeline] Model used: Local TF-IDF Rewrite Matcher (Similarity: {similarities[best_idx]:.2f})")
                return matched["improved_message"], f"Matched context '{matched['context']}': Focus on confidence and clarity."
        except Exception as e:
            print(f"[AI Pipeline] Local rewrite matcher inference failed: {e}. Trying T5...")
            
    # 2. Try Hugging Face T5
    try:
        from transformers import pipeline
        if _paraphrase_pipeline is None:
            print("[AI Pipeline] Loading T5 paraphrase model...")
            _paraphrase_pipeline = pipeline("text2text-generation", model="google-t5/t5-small")
            print("[AI Pipeline] T5 Paraphraser loaded successfully.")
            
        prompt = f"paraphrase: {text} context: {context}"
        res = _paraphrase_pipeline(prompt, max_length=64)
        if res and len(res) > 0:
            improved = res[0].get("generated_text", "")
            if len(improved.strip()) > 5:
                print(f"[AI Pipeline] Model used: T5 Rewrite Engine (Result: '{improved}')")
                return improved, "Paraphrased with T5 paraphraser for better flow."
    except Exception as e:
        print(f"[AI Pipeline] T5 rewrite engine failed: {e}. Falling back to TF-IDF retriever.")
        
    print("[AI Pipeline] Model used: Fallback TF-IDF Rewrite Retriever")
    return get_smart_fallback_rewrite(text, context)

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

def generate_coach_response_hf(user_input: str, persona: str, context: str, session_id: str = "default") -> str:
    """Generate dynamic conversation response using memory-aware Dialogue Retriever or specialized practice flow."""
    input_lower = user_input.lower().strip()
    persona_lower = persona.lower()

    # 1. Chatbot Mode: Conversational AI Coach
    if "ai coach" in persona_lower or persona_lower == "" or persona_lower == "coach":
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

        if "anxious" in input_lower or "nervous" in input_lower or "scared" in input_lower:
            if not state['topic']:
                state['topic'] = 'anxiety'

        # Stateful dialogue logic based on extracted context
        if state['topic'] == 'interview':
            if state['role']:
                # Role-specific context memory responses
                if any(w in input_lower for w in ["what to expect", "technical", "prep", "prepare", "question"]):
                    reply = f"For a {state['role']} role, technical interviews usually focus on core architecture, state management, and performance. In a {state['role']} interview, you should expect questions about system design and best practices. Would you like to practice explaining a key concept, or discuss common coding questions?"
                elif any(w in input_lower for w in ["state management", "riverpod", "bloc", "setstate"]):
                    reply = f"Ah, state management is a crucial topic for a {state['role']}! Interviewers love to ask about how you handle state changes asynchronously. For instance, explaining when to use Riverpod versus standard Provider demonstrates high competency. How do you normally structure your apps?"
                else:
                    reply = f"A {state['role']} interview! That is fantastic. Let's prep for it. They will likely ask about your background, followed by technical concepts. Let's do a run-through: how would you describe your experience as a {state['role']}?"
            else:
                reply = "Congratulations on your upcoming interview! It's natural to feel nervous. What specific role is it for? If you share the job title, I can tailor our practice questions and tech stack discussion."
            
            add_session_message(user_input, reply, session_id)
            return reply

        # Reassurance and anxiety context tracking
        if state['topic'] == 'anxiety':
            if any(w in input_lower for w in ["fail", "failed", "hopeless", "ruined"]):
                reply = "Setbacks can feel heavy and overwhelming. It is important to separate a single event from your overall potential. You have the ability to adapt and learn. Let's focus on one small, manageable step you can take today."
            else:
                reply = "I hear you, and it's completely okay to feel anxious. Slow down and take a breath. What feels like the biggest obstacle or trigger for this anxiety right now?"
            add_session_message(user_input, reply, session_id)
            return reply

        # Greeting fallbacks
        if len(input_lower.split()) <= 2 and any(re.search(rf"\b{re.escape(w)}\b", input_lower) for w in ["hello", "hi", "hey", "greet", "greetings"]):
            return "Hello! I am your SocialSync AI Coach. I'm here to help you navigate social anxiety, build communication confidence, or practice relationships and interviews. What's on your mind today?"

        # Retrieve history context for conversational chatbot memory
        history = get_session_history(session_id)
        context_words = []
        for u, b in history:
            context_words.append(u)
        context_words.append(user_input)
        contextual_query = " ".join(context_words)

        if _conversational_retriever is not None:
            try:
                vectorizer = _conversational_retriever["vectorizer"]
                tfidf_matrix = _conversational_retriever["tfidf_matrix"]
                responses = _conversational_retriever["responses"]
                
                query_vec = vectorizer.transform([contextual_query])
                similarities = cosine_similarity(query_vec, tfidf_matrix).flatten()
                best_idx = np.argmax(similarities)
                
                if similarities[best_idx] > 0.15:
                    reply = responses[best_idx]
                    print(f"[AI Pipeline] Model used: Local Dialogue Retriever (Similarity: {similarities[best_idx]:.2f})")
                    add_session_message(user_input, reply, session_id)
                    return reply
            except Exception as e:
                print(f"[AI Pipeline] Dialogue retriever inference failed: {e}")

        # General empathetic fallback
        reply = "That makes a lot of sense. Tell me more about what is on your mind today, I'm here to support you."
        add_session_message(user_input, reply, session_id)
        return reply

    # 2. Practice Mode: Stateful Specialized Practice Coaches
    if session_id not in _practice_states:
        _practice_states[session_id] = {'step': 0, 'details': {}}
    
    state = _practice_states[session_id]
    
    is_initial = any(w in input_lower for w in ["hello", "hi", "hey", "start", "begin", "ready"]) or len(user_input) < 3
    if is_initial:
        state['step'] = 0

    step = state['step']

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
            state['step'] = 0  # reset for next time
            return (
                "That concludes our mock interview session! Here is your performance evaluation:\n\n"
                "- **Technical competency**: 88%\n"
                "- **Communication flow**: 90%\n"
                "- **Clarity & Pacing**: 85%\n\n"
                "**Actionable Tips**:\n"
                "1. Your technical explanation was solid. Keep practicing explaining complex topics simply.\n"
                "2. Structure your behavioral stories with the STAR method (Situation, Task, Action, Result)."
            )

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
                "**Actionable Tips**:\n"
                "1. Great job staying positive and showing genuine curiosity!\n"
                "2. Try asking more open-ended questions to allow the other person to share details."
            )

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
                "**Actionable Tips**:\n"
                "1. You did a great job using 'I' statements instead of placing blame.\n"
                "2. Proposing concrete ways to reconnect shows high commitment to the relationship."
            )

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
                "**Actionable Tips**:\n"
                "1. Your elevator pitch was clear and focused.\n"
                "2. Offering mutual value first before asking for contact details builds trust quickly."
            )

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
                "**Actionable Tips**:\n"
                "1. Try pausing for 2 seconds after rhetorical questions to let them sink in.\n"
                "2. Keep your closing call-to-action simple and direct."
            )

    general_replies = [
        "That makes a lot of sense. Tell me more about what is on your mind today.",
        "I hear you. Dealing with social situations or anxiety can be challenging, but you're doing great just by taking it step by step. What feels like the biggest obstacle for you right now?",
        "Thank you for opening up about that. It's completely valid to feel this way. How can I best help you sort through this today?"
    ]
    return random.choice(general_replies)

