import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
    avAudioSessionMode: AVAudioSessionMode.voiceChat,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.speech,
      flags: AndroidAudioFlags.none,
      usage: AndroidAudioUsage.voiceCommunication,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  ));

  await session.setActive(true);

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('first_time') ?? true;

  runApp(FridayApp(isFirstTime: isFirstTime));
}

class FridayApp extends StatelessWidget {
  final bool isFirstTime;
  const FridayApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEXTA-FEIRA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF040A10),
        colorScheme: ThemeData.dark()
            .colorScheme
            .copyWith(primary: const Color(0xFF35E4E0)),
      ),
      
      home: isFirstTime ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
