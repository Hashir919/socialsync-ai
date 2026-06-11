import os
import sys

def init_whisper_pipeline(model_name: str = "small"):
    """Initialize Whisper speech-to-text pipeline.
    This prepares the architecture for future voice emotion analysis and speech-to-text.
    """
    print(f"Initializing Whisper transcription pipeline with model size: {model_name}...")
    try:
        import whisper
        # Load the model (caches locally)
        model = whisper.load_model(model_name)
        return model
    except ImportError:
        print("[Warning] 'openai-whisper' package is not installed or available. Using fallback mock model.")
        return None

def transcribe_audio_file(audio_path: str, model=None) -> dict:
    """Transcribe audio file and return text + structural information."""
    if not os.path.exists(audio_path):
        return {"error": f"Audio file not found: {audio_path}", "text": ""}
        
    if model is None:
        # Return mock transcription for testing
        print("[Mock] Transcribing audio file...")
        return {
            "text": "Hello, I am practicing my introduction. I am a bit nervous but excited.",
            "segments": [
                {"start": 0.0, "end": 2.5, "text": "Hello, I am practicing my introduction."},
                {"start": 2.5, "end": 5.0, "text": "I am a bit nervous but excited."}
            ],
            "language": "en"
        }
        
    try:
        result = model.transcribe(audio_path)
        return {
            "text": result.get("text", ""),
            "segments": result.get("segments", []),
            "language": result.get("language", "en")
        }
    except Exception as e:
        return {"error": str(e), "text": ""}

if __name__ == "__main__":
    # Test execution
    model = init_whisper_pipeline("tiny")
    res = transcribe_audio_file("dummy.wav", model)
    print("Transcribe result:", res)
