
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VoiceEngineService {
  Process? _process;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;

  final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  Stream<String> get events => _eventController.stream;

  bool get isRunning => _process != null;

  Future<void> start() async {
    if (isRunning) return;

    final projectPath = Directory.current.path;
    final voiceDirectory = '$projectPath\\voice_engine';
    final pythonPath = '$voiceDirectory\\.venv\\Scripts\\python.exe';
    final scriptPath = '$voiceDirectory\\kws_optimus_test.py';

    if (!File(pythonPath).existsSync()) {
      throw Exception('Python virtual environment not found: $pythonPath');
    }

    if (!File(scriptPath).existsSync()) {
      throw Exception('Voice engine script not found: $scriptPath');
    }

    final process = await Process.start(
      pythonPath,
      [scriptPath],
      workingDirectory: voiceDirectory,
      runInShell: false,
    );

    _process = process;

    _outputSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith('Detected:')) {
        _eventController.add('wake_word_detected');
      }
    });

    _errorSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stderr.writeln('Voice engine: $line');
    });

    process.exitCode.then((code) {
      if (identical(_process, process)) {
        _process = null;
      }
      stderr.writeln('Voice engine stopped with code $code');
    });
  }

  Future<void> stop() async {
    await _outputSubscription?.cancel();
    await _errorSubscription?.cancel();

    _outputSubscription = null;
    _errorSubscription = null;

    final process = _process;
    _process = null;

    process?.kill();
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}