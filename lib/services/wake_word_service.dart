// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class WakeWordService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final stt.SpeechToText _speech = stt.SpeechToText();

  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _voskService;

  Function()? _onWakeWordDetected;
  Function(String)? _onCommandPartial;
  Function(String)? _onCommandFinal;

  bool _isTransitioning = false;

  Future<String?> initVosk({
    required Function() onWakeWordDetected,
    required Function(String) onCommandPartial,
    required Function(String) onCommandFinal,
  }) async {
    _onWakeWordDetected = onWakeWordDetected;
    _onCommandPartial = onCommandPartial;
    _onCommandFinal = onCommandFinal;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return 'Permissão de microfone negada!';
    }

    try {
      await _speech.initialize(onError: (val) => print('Erro STT: $val'));

      final modelPath = await ModelLoader()
          .loadFromAssets('assets/models/vosk-model-small-pt.zip');
      _model = await _vosk.createModel(modelPath);
      _recognizer =
          await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      _voskService = await _vosk.initSpeechService(_recognizer!);

      _voskService!.onPartial().listen((event) {
        if (_isTransitioning) return;

        final result = jsonDecode(event);
        final String textoOuvido =
            result['partial'].toString().toLowerCase().trim();

        final gatilhos = ['sexta-feira', 'sexta feira'];
        if (gatilhos.any((palavra) => textoOuvido.contains(palavra))) {
          _iniciarModoComando();
        }
      });

      await _voskService!.start();
      return null;
    } catch (e) {
      return 'Erro no sistema Híbrido: $e';
    }
  }

  Future<void> _iniciarModoComando() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    _onWakeWordDetected?.call();

    await _voskService?.stop();
    await Future.delayed(const Duration(milliseconds: 250));

    await _speech.listen(
      onResult: (val) async {
        String texto = val.recognizedWords.toLowerCase().trim();
        _onCommandPartial?.call(texto);

        if (val.finalResult) {
          _onCommandFinal?.call(texto);

          await _speech.stop();
          await Future.delayed(const Duration(milliseconds: 250));
          await _voskService?.start();
          _isTransitioning = false;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'pt_BR',
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> startListening() async {
    if (!_isTransitioning) {
      await _iniciarModoComando();
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    await _voskService?.stop();
    _isTransitioning = false;
  }
}
