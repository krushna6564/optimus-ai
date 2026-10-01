from pathlib import Path
from piper import PiperVoice
import sounddevice as sd

MODEL_PATH = Path("models/piper/en_US-lessac-medium.onnx")

# Load the offline voice
voice = PiperVoice.load(str(MODEL_PATH))

def speak(text):
    audio_chunks = []

    for chunk in voice.synthesize(text):
        audio_chunks.append(chunk.audio_int16)

    if not audio_chunks:
        return

    import numpy as np

    audio = np.concatenate(audio_chunks)
    sd.play(audio, samplerate=voice.config.sample_rate)
    sd.wait()


if __name__ == "__main__":
    speak("Hello Krushna. I am Optimus. My voice system is ready.")