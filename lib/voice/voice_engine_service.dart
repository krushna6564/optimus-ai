
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VoiceEngineService {
  Process? _process;
  StreamSubscription<String>? _output;
  StreamSubscription<String>? _error;
  final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  Stream<String> get events => _eventController.stream;

  bool get isRunning => _process != null;

  Future<void> start() async {
    if (isRunning) return;

    final projectPath = Directory.current.path;
    final voiceDirectory = '$projectPath\\voice_engine';
    final pythonPath = '$voiceDirectory\\.venv\\Scripts\\python.exe';
    final scriptPath = '$voiceDirectory\\optimus_voice.py';

    if (!File(pythonPath).existsSync()) {
      throw Exception('Python environment not found: $pythonPath');
    }

    if (!File(scriptPath).existsSync()) {
      throw Exception('Voice engine script not found: $scriptPath');
    }

    final process = await Process.start(
      pythonPath,
      ['-u', scriptPath],
      workingDirectory: voiceDirectory,
      runInShell: false,
    );

    _process = process;

    _output = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line == 'VOICE_READY') {
        _eventController.add('voice_ready');
      } else if (line == 'WAKE_WORD_DETECTED') {
        _eventController.add('wake_word_detected');
      } else if (line.startsWith('TRANSCRIPT:')) {
        final transcript = line.substring('TRANSCRIPT:'.length).trim();
        if (transcript.isNotEmpty) {
          _eventController.add('transcript:$transcript');
        }
      } else if (line == 'LISTENING_FOR_WAKE_WORD') {
        _eventController.add('listening_for_wake_word');
      }
    });

    _error = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stderr.writeln('Voice engine: $line');
      _eventController.add('voice_error:$line');
    });

    process.exitCode.then((code) {
      if (identical(_process, process)) {
        _process = null;
        _eventController.add('voice_stopped');
      }
      stderr.writeln('Voice engine exited: $code');
    });
  }

  Future<void> stop() async {
    final process = _process;
    _process = null;

    await _output?.cancel();
    await _error?.cancel();
    _output = null;
    _error = null;

    if (process != null) {
      process.kill();
      await process.exitCode;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}