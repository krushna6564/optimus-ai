import sherpa_onnx
from pvrecorder import PvRecorder


MODEL_DIR = r"models\sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01"

KEYWORDS_FILE = rf"{MODEL_DIR}\keywords.txt"
TOKENS_FILE = rf"{MODEL_DIR}\tokens.txt"
ENCODER_FILE = rf"{MODEL_DIR}\encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx"
DECODER_FILE = rf"{MODEL_DIR}\decoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx"
JOINER_FILE = rf"{MODEL_DIR}\joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx"


spotter = sherpa_onnx.KeywordSpotter(
    tokens=TOKENS_FILE,
    encoder=ENCODER_FILE,
    decoder=DECODER_FILE,
    joiner=JOINER_FILE,
    keywords_file=KEYWORDS_FILE,
    num_threads=2,
    sample_rate=16000,
    feature_dim=80,
    keywords_score=1.0,
    keywords_threshold=0.25,
    provider="cpu",
)

stream = spotter.create_stream()

recorder = PvRecorder(
    device_index=0,
    frame_length=512,
)

print("OPTIMUS wake-word test started.")
print("Say: HEY SIRI")
print("Press Ctrl+C to stop.\n")

recorder.start()

try:
    while True:
        samples = recorder.read()
        stream.accept_waveform(16000, samples)

        while spotter.is_ready(stream):
            spotter.decode_stream(stream)

        result = spotter.get_result(stream)

        if result:
            print(f"Detected: {result}")
            spotter.reset_stream(stream)

except KeyboardInterrupt:
    print("\nStopping...")

finally:
    recorder.stop()
    recorder.delete()
