
import sys
import sounddevice as sd
import sherpa_onnx

MODEL_DIR = "models/sherpa-onnx-zipformer-gigaspeech-2023-12-12"

SAMPLE_RATE = 16000
DEVICE = 1
BLOCK_SIZE = 1600

recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
    tokens=f"{MODEL_DIR}/tokens.txt",
    encoder=f"{MODEL_DIR}/encoder-epoch-30-avg-1.int8.onnx",
    decoder=f"{MODEL_DIR}/decoder-epoch-30-avg-1.onnx",
    joiner=f"{MODEL_DIR}/joiner-epoch-30-avg-1.int8.onnx",
    num_threads=2,
    sample_rate=SAMPLE_RATE,
    feature_dim=80,
    decoding_method="greedy_search",
    provider="cpu",
)

print("STT_READY", flush=True)

print("OPTIMUS speech recognition is ready.", flush=True)

try:
    with sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
        device=DEVICE,
        blocksize=BLOCK_SIZE,
    ) as audio_stream:

        audio_buffer = []
        silence_blocks = 0
        speech_started = False

        # Basic voice activity thresholds
        SILENCE_THRESHOLD = 0.015
        SILENCE_LIMIT = 15
        MIN_AUDIO_BLOCKS = 8

        while True:
            samples, overflowed = audio_stream.read(BLOCK_SIZE)
            samples = samples[:, 0]

            # Calculate the audio level
            rms = (sum(float(x) ** 2 for x in samples) / len(samples)) ** 0.5

            if rms > SILENCE_THRESHOLD:
                speech_started = True
                silence_blocks = 0
                audio_buffer.extend(samples.tolist())
            elif speech_started:
                silence_blocks += 1
                audio_buffer.extend(samples.tolist())

            # Stop a recording after enough silence
            if speech_started and silence_blocks >= SILENCE_LIMIT:
                if len(audio_buffer) >= BLOCK_SIZE * MIN_AUDIO_BLOCKS:
                    stream = recognizer.create_stream()
                    stream.accept_waveform(
                        SAMPLE_RATE,
                        audio_buffer,
                    )
                    recognizer.decode_stream(stream)

                    text = stream.result.text.strip()
                    if text:
                        print(f"TRANSCRIPT:{text}", flush=True)

                audio_buffer = []
                silence_blocks = 0
                speech_started = False

except KeyboardInterrupt:
    print("STT_STOPPED", flush=True)
except Exception as error:
    print(f"STT_ERROR:{error}", file=sys.stderr, flush=True)
    raise