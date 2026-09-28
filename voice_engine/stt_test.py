
import sounddevice as sd
import sherpa_onnx

MODEL_DIR = "models/sherpa-onnx-zipformer-gigaspeech-2023-12-12"

# Load the offline speech recognition model
recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
    tokens=f"{MODEL_DIR}/tokens.txt",
    encoder=f"{MODEL_DIR}/encoder-epoch-30-avg-1.int8.onnx",
    decoder=f"{MODEL_DIR}/decoder-epoch-30-avg-1.onnx",
    joiner=f"{MODEL_DIR}/joiner-epoch-30-avg-1.int8.onnx",
    num_threads=2,
    sample_rate=16000,
    feature_dim=80,
    decoding_method="greedy_search",
    provider="cpu",
)

SAMPLE_RATE = 16000
DEVICE = 1
DURATION = 5

print("OPTIMUS speech recognition started.")
print("Speak a short English sentence.")
print("Press Ctrl+C to stop.\n")

try:
    while True:
        input("Press Enter to record for 5 seconds...")

        print("Listening...")

        audio = sd.rec(
            int(DURATION * SAMPLE_RATE),
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            device=DEVICE,
        )
        sd.wait()

        # Create a new stream for each recording
        stream = recognizer.create_stream()
        stream.accept_waveform(SAMPLE_RATE, audio[:, 0])

        # Decode the recorded audio
        recognizer.decode_stream(stream)

        # Get the recognized text
        result = stream.result
        print("Recognized:", result.text or "(No speech detected)", "\n")

except KeyboardInterrupt:
    print("\nStopping speech recognition...")