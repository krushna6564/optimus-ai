
import sys
import re
from collections import deque
from datetime import datetime

import sounddevice as sd
import sherpa_onnx

# Model paths
KWS_MODEL_DIR = r"models\sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01"
ASR_MODEL_DIR = r"models\sherpa-onnx-zipformer-gigaspeech-2023-12-12"

SAMPLE_RATE = 16000
DEVICE = 2
BLOCK_SIZE = 1600

# Keep recent audio so commands are not cut off
PRE_ROLL_BLOCKS = 15

# Wake-word detection
spotter = sherpa_onnx.KeywordSpotter(
    tokens=rf"{KWS_MODEL_DIR}\tokens.txt",
    encoder=rf"{KWS_MODEL_DIR}\encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx",
    decoder=rf"{KWS_MODEL_DIR}\decoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx",
    joiner=rf"{KWS_MODEL_DIR}\joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx",
    keywords_file="custom_keywords_tokens.txt",
    num_threads=2,
    sample_rate=SAMPLE_RATE,
    feature_dim=80,
    keywords_score=2.0,
    keywords_threshold=0.05,
    provider="cpu",
)

# Speech recognition
recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
    tokens=rf"{ASR_MODEL_DIR}\tokens.txt",
    encoder=rf"{ASR_MODEL_DIR}\encoder-epoch-30-avg-1.int8.onnx",
    decoder=rf"{ASR_MODEL_DIR}\decoder-epoch-30-avg-1.onnx",
    joiner=rf"{ASR_MODEL_DIR}\joiner-epoch-30-avg-1.onnx",
    num_threads=2,
    sample_rate=SAMPLE_RATE,
    feature_dim=80,
    decoding_method="greedy_search",
    provider="cpu",
)


def clean_transcript(text):
    """Remove common wake-word variations from the start."""
    text = text.strip()

    # Normalize punctuation for checking
    cleaned = re.sub(r"[^\w\s]", " ", text.upper())
    cleaned = " ".join(cleaned.split())

    wake_phrases = [
        "HEY OPTIMUS",
        "HEY OPTIMAS",
        "HEY OPTIMERS",
        "A OPTIMUS",
        "OPTIMUS",
        "OPTIMAS",
        "OPTIMERS",
    ]

    for phrase in wake_phrases:
        if cleaned.startswith(phrase):
            # Remove the matching phrase from the original transcript
            words_to_remove = len(phrase.split())
            original_words = text.split()
            return " ".join(original_words[words_to_remove:]).strip(" ,.!?")

    return text.strip(" ,.!?")


def process_command(text):
    """Process recognized commands and return a response."""
    command = text.lower().strip()
    command = re.sub(r"[^\w\s]", "", command)
    command = " ".join(command.split())

    # Time command
    if (
        "what is the time" in command
        or "what time is it" in command
        or "tell me the time" in command
    ):
        current_time = datetime.now().astimezone().strftime("%I:%M %p")
        return f"The time is {current_time}."

    # Name command
    if (
        "what is my name" in command
        or "what's my name" in command
        or "who am i" in command
    ):
        return "Your name is Krushna ."

    return "Sorry, I don't know how to handle that command yet."


print("VOICE_READY", flush=True)
print("OPTIMUS is listening for HEY OPTIMUS.", flush=True)

stream = spotter.create_stream()
listening_for_command = False
audio_buffer = []
recent_audio = deque(maxlen=PRE_ROLL_BLOCKS)
silence_blocks = 0

SILENCE_THRESHOLD = 0.015
SILENCE_LIMIT = 25
MIN_AUDIO_BLOCKS = 8

try:
    with sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
        device=DEVICE,
        blocksize=BLOCK_SIZE,
    ) as audio_stream:

        while True:
            samples, _ = audio_stream.read(BLOCK_SIZE)
            samples = samples[:, 0]

            rms = (
                sum(float(x) ** 2 for x in samples) / len(samples)
            ) ** 0.5

            if not listening_for_command:
                # Keep a rolling history of recent microphone audio
                recent_audio.append(samples.tolist())

                stream.accept_waveform(SAMPLE_RATE, samples)

                while spotter.is_ready(stream):
                    spotter.decode_stream(stream)

                result = spotter.get_result(stream)

                if result:
                    print("WAKE_WORD_DETECTED", flush=True)

                    listening_for_command = True

                    # Include recent audio to avoid losing speech
                    audio_buffer = [
                        sample
                        for block in recent_audio
                        for sample in block
                    ]

                    silence_blocks = 0
                    recent_audio.clear()
                    spotter.reset_stream(stream)

            else:
                audio_buffer.extend(samples.tolist())

                if rms > SILENCE_THRESHOLD:
                    silence_blocks = 0
                else:
                    silence_blocks += 1

                if silence_blocks >= SILENCE_LIMIT:
                    if len(audio_buffer) >= BLOCK_SIZE * MIN_AUDIO_BLOCKS:
                        asr_stream = recognizer.create_stream()
                        asr_stream.accept_waveform(
                            SAMPLE_RATE, audio_buffer
                        )
                        recognizer.decode_stream(asr_stream)

                        raw_text = asr_stream.result.text.strip()
                        text = clean_transcript(raw_text)

                        if text:
                            print(f"TRANSCRIPT:{text}", flush=True)

                            response = process_command(text)
                            print(f"OPTIMUS: {response}", flush=True)

                    # Reset for the next wake word
                    audio_buffer = []
                    silence_blocks = 0
                    listening_for_command = False
                    stream = spotter.create_stream()
                    recent_audio.clear()

                    print("LISTENING_FOR_WAKE_WORD", flush=True)

except KeyboardInterrupt:
    print("VOICE_STOPPED", flush=True)

except Exception as error:
    print(f"VOICE_ERROR:{error}", file=sys.stderr, flush=True)
    raise