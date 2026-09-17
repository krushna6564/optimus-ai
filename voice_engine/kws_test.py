import sounddevice as sd
import sherpa_onnx


MODEL_DIR = r"models\sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01"

KEYWORDS_FILE = rf"{MODEL_DIR}\keywords.txt"
TOKENS_FILE = rf"{MODEL_DIR}\tokens.txt"
ENCODER_FILE = rf"{MODEL_DIR}\encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx"
DECODER_FILE = rf"{MODEL_DIR}\decoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx"
JOINER_FILE = rf"{MODEL_DIR}\joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx"

SAMPLE_RATE = 16000
DEVICE = 1


spotter = sherpa_onnx.KeywordSpotter(
    tokens=TOKENS_FILE,
    encoder=ENCODER_FILE,
    decoder=DECODER_FILE,
    joiner=JOINER_FILE,
    keywords_file=KEYWORDS_FILE,
    num_threads=2,
    sample_rate=SAMPLE_RATE,
    feature_dim=80,
    keywords_score=1.0,
    keywords_threshold=0.25,
    provider="cpu",
)

stream = spotter.create_stream()

print("OPTIMUS wake-word test started.")
print("Microphone: Realtek Audio")
print("Say: HEY SIRI")
print("Press Ctrl+C to stop.\n")


try:
    with sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
        device=DEVICE,
        blocksize=1600,
    ) as audio_stream:

        while True:
            samples, _ = audio_stream.read(1600)

            samples = samples[:, 0]

            stream.accept_waveform(SAMPLE_RATE, samples)

            while spotter.is_ready(stream):
                spotter.decode_stream(stream)

            result = spotter.get_result(stream)

            if result:
                print(f"Detected: {result}")
                spotter.reset_stream(stream)

except KeyboardInterrupt:
    print("\nStopping...")
