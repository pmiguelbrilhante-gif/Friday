// ignore_for_file: avoid_print
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.55); 
    await _tts.setPitch(1.0); 
    await _tts.setVolume(1.2);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stopSpeaking();

    try {
      
      await _tts.speak(text);
    } catch (e) {
      print("Erro no motor de voz: $e");
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    try {
      await _player.stop();
    } catch (_) {}
  }
}