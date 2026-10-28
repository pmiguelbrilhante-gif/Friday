import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../widgets/hud_background.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _concluirTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false); 
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF35E4E0);
    return Scaffold(
      backgroundColor: const Color(0xFF040A10),
      body: HudBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.memory, color: cyan, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'INICIALIZAÇÃO DO SISTEMA\nSEXTA-FEIRA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bem-vindo(a).\n\nEu sou a Sexta-feira, a sua assistente virtual de operação local. '
                  'Fui projetada para gerenciar o seu dispositivo de forma rápida, offline e segura.\n\n'
                  'Importante: Eu opero através de Protocolos de Comandos Fixos. Isso significa que não sou uma I.A. conversacional comum, '
                  'mas sim um núcleo de resposta rápida a ordens específicas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const Spacer(),
                const Text(
                  'O Manual de Protocolos completo pode ser acessado a qualquer momento nas Configurações (ícone de engrenagem).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _concluirTutorial(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan.withValues(alpha: 0.15),
                      side: const BorderSide(color: cyan),
                    ),
                    child: const Text('INICIAR PROTOCOLOS', style: TextStyle(color: cyan, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}