
from pathlib import Path
from piper import PiperVoice
from pedalboard import Pedalboard, PitchShift, Reverb, LowpassFilter
import numpy as np
import sounddevice as sd

model_path = Path("models/piper/en_US-hfc_male-medium.onnx")

voice = PiperVoice.load(str(model_path))

text = "Hello Krushna. I am Optimus. How can I help you?"

audio_chunks = []

for chunk in voice.synthesize(text):
    audio_chunks.append(chunk.audio_float_array)

audio = np.concatenate(audio_chunks)

# Add a deeper, metallic sound
effects = Pedalboard([
    PitchShift(semitones=-0.5)
])

audio = effects(audio, voice.config.sample_rate)
audio = np.asarray(audio, dtype=np.float32)

# Prevent clipping
peak = np.max(np.abs(audio))
if peak > 0.95:
    audio = audio * (0.95 / peak)

print("Playing robotic OPTIMUS voice...")
sd.play(audio, samplerate=voice.config.sample_rate)
sd.wait()
print("Playback finished.")