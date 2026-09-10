from pvrecorder import PvRecorder
import time

recorder = PvRecorder(
    device_index=0,
    frame_length=512,
)

recorder.start()

print("Speak now for 5 seconds...")

start_time = time.time()
max_value = 0
min_value = 0
total = 0
count = 0

while time.time() - start_time < 5:
    samples = recorder.read()

    max_value = max(max_value, max(samples))
    min_value = min(min_value, min(samples))

    total += sum(abs(x) for x in samples)
    count += len(samples)

recorder.stop()
recorder.delete()

print()
print("Min:", min_value)
print("Max:", max_value)
print("Average:", total / count)