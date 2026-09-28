
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VoiceEngineService {
  Process? _kwsProcess;
  Process? _sttProcess;

  StreamSubscription<String>? _kwsOutput;
  StreamSubscription<String>? _kwsError;
  StreamSubscription<String>? _sttOutput;
  StreamSubscription<String>? _sttError;

  final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  Stream<String> get events => _eventController.stream;

  bool get isRunning =>
      _kwsProcess != null || _sttProcess != null;

  Future<void> start() async {
    if (isRunning) return;

    final projectPath = Directory.current.path;
    final voiceDirectory = '$projectPath\\voice_engine';
    final pythonPath = '$voiceDirectory\\.venv\\Scripts\\python.exe';

    final kwsScript = '$voiceDirectory\\kws_optimus_test.py';
    final sttScript = '$voiceDirectory\\stt_engine.py';

    if (!File(pythonPath).existsSync()) {
      throw Exception('Python environment not found: $pythonPath');
    }

    if (!File(kwsScript).existsSync()) {
      throw Exception('Wake-word script not found: $kwsScript');
    }

    if (!File(sttScript).existsSync()) {
      throw Exception('STT script not found: $sttScript');
    }

    try {
      _kwsProcess = await Process.start(
        pythonPath,
        ['-u', kwsScript],
        workingDirectory: voiceDirectory,
        runInShell: false,
      );

      _kwsOutput = _kwsProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('Detected:')) {
          _eventController.add('wake_word_detected');
        }
      });

      _kwsError = _kwsProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.writeln('Wake-word engine: $line');
      });

      _sttProcess = await Process.start(
        pythonPath,
        ['-u', sttScript],
        workingDirectory: voiceDirectory,
        runInShell: false,
      );

      _sttOutput = _sttProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('TRANSCRIPT:')) {
          final transcript = line.substring('TRANSCRIPT:'.length).trim();
          if (transcript.isNotEmpty) {
            _eventController.add('transcript:$transcript');
          }
        }
      });

      _sttError = _sttProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderr.writeln('Speech recognition: $line');
      });

      _kwsProcess!.exitCode.then((code) {
        stderr.writeln('Wake-word engine exited: $code');
        if (identical(_kwsProcess, _kwsProcess)) {
          _kwsProcess = null;
        }
      });

      _sttProcess!.exitCode.then((code) {
        stderr.writeln('Speech recognition exited: $code');
        _sttProcess = null;
      });
    } catch (error) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _kwsOutput?.cancel();
    await _kwsError?.cancel();
    await _sttOutput?.cancel();
    await _sttError?.cancel();

    _kwsOutput = null;
    _kwsError = null;
    _sttOutput = null;
    _sttError = null;

    final kws = _kwsProcess;
    final stt = _sttProcess;

    _kwsProcess = null;
    _sttProcess = null;

    kws?.kill();
    stt?.kill();

    if (kws != null) {
      await kws.exitCode;
    }
    if (stt != null) {
      await stt.exitCode;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}