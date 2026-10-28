import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_brain_service.dart';
import '../services/action_executor.dart';
import '../services/voice_service.dart';
import '../services/wake_word_service.dart';
import '../widgets/arc_reactor.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/hud_background.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voice = VoiceService();
  final WakeWordService _wakeWordService = WakeWordService();
  LocalBrainService? _brain;

  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  FridayState _state = FridayState.idle;
  String _statusLabel = 'Iniciando sistemas...';
  String _partialSpeech = '';

  bool _wakeWordActive = false;
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _voice.init();
    await _loadBrain();

    final erroVosk = await _wakeWordService.initVosk(
        onWakeWordDetected: _onWakeWordDetected,
        onCommandPartial: (text) {
          if (mounted) setState(() => _partialSpeech = text);
        },
        onCommandFinal: (text) {
          if (mounted) _handleUserInput(text);
        });

    if (mounted) {
      setState(() {
        if (erroVosk != null) {
          _statusLabel = erroVosk;
        } else {
          _statusLabel = 'Sistemas online. Diga SEXTA-FEIRA.';
        }
      });
    }
  }

  void _onWakeWordDetected() {
    _voice.stopSpeaking();
    if (_state != FridayState.listening) {
      if (mounted) {
        setState(() {
          _state = FridayState.listening;
          _statusLabel = 'Ouvindo...';
          _partialSpeech = '';
        });
      }
    }
  }

  Future<void> _toggleBackgroundListening() async {
    if (!_wakeWordActive) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          setState(() => _statusLabel = 'Permissão de microfone negada.');
        }
        return;
      }
      await _wakeWordService.startListening();
    } else {
      await _wakeWordService.stopListening();
    }
    setState(() => _wakeWordActive = !_wakeWordActive);
  }

  Future<void> _loadBrain() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Senhor';
    final homeAddress = prefs.getString('home_address') ?? '';

    setState(() {
      _brain = LocalBrainService(userName: userName, homeAddress: homeAddress);
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true) await _loadBrain();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_brain == null) return;

    if (_state == FridayState.listening) {

      setState(() {
        _state = FridayState.idle;
        _statusLabel = 'Sistemas online. Diga SEXTA-FEIRA.';
        _partialSpeech = '';
      });
      return;
    }

    await _voice.stopSpeaking();

    await _wakeWordService.startListening();

    setState(() {
      _state = FridayState.listening;
      _statusLabel = 'Ouvindo...';
      _partialSpeech = '';
    });
  }

  Future<void> _handleUserInput(String text) async {
    if (text.isEmpty || _brain == null) {
      setState(() {
        _state = FridayState.idle;
        _statusLabel = 'Sistemas online. Diga SEXTA-FEIRA.';
      });
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text, true));
      _state = FridayState.thinking;
      _statusLabel = 'Processando...';
      _partialSpeech = '';
      _inputCtrl.clear();
    });
    _scrollToBottom();

    bool continuarOuvindo = false; 

    try {
      final response = await _brain!.processCommand(text);
      String? replyText = response.text;
      continuarOuvindo = response.keepListening; 

      if (response.hasAction) {
        try {
          final result = await ActionExecutor.executeAction(
              response.functionName!, response.args ?? {});
          replyText = result;
        } catch (e) {
          replyText = 'Não consegui concluir isso: $e';
        }
      }

      replyText ??= 'Pronto.';

      setState(() {
        _messages.add(ChatMessage(replyText!, false));
        _state = FridayState.speaking;
        _statusLabel = 'Falando...';
      });
      _scrollToBottom();

      await _voice.speak(replyText);

      if (mounted) {
        if (continuarOuvindo) {
          
          await _toggleListening();
        } else {
          
          setState(() {
            _state = FridayState.idle;
            _statusLabel = 'Sistemas online. Diga SEXTA-FEIRA.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Erro interno: $e', false));
        _state = FridayState.idle;
        _statusLabel = 'Sistemas online. Diga SEXTA-FEIRA.';
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _wakeWordService.stopListening();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF35E4E0);

    return Scaffold(
      backgroundColor: const Color(0xFF040A10),
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(cyan),
              const SizedBox(height: 6),

              ArcReactor(
                state: _state,
                size: MediaQuery.of(context).size.width * 0.85,
                onTap: _toggleListening,
              ),
              const SizedBox(height: 10),
              Text(
                _partialSpeech.isNotEmpty ? _partialSpeech : _statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cyan.withValues(alpha: 0.85),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildChatList()),
              _showKeyboard
                  ? _buildInputBar(cyan)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 10),
                      child: IconButton(
                        icon: Icon(Icons.keyboard,
                            color: cyan.withValues(alpha: 0.5), size: 32),
                        onPressed: () => setState(() => _showKeyboard = true),
                        tooltip: 'Abrir terminal de texto',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color cyan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Text(
            'FRIDAY',
            style: TextStyle(
              color: cyan,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 3,
              shadows: [
                Shadow(color: cyan.withValues(alpha: 0.6), blurRadius: 16)
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon:
                const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            tooltip: 'Interromper FRIDAY',
            onPressed: () async => await _voice.stopSpeaking(),
          ),
          IconButton(
            onPressed: _toggleBackgroundListening,
            icon: Icon(
              _wakeWordActive ? Icons.hearing : Icons.hearing_disabled,
              color: _wakeWordActive ? cyan : Colors.white38,
            ),
            tooltip: 'Ligar palavra de ativação',
          ),
          IconButton(
            onPressed: () => setState(() => _messages.clear()),
            icon: const Icon(Icons.refresh, color: Colors.white38),
            tooltip: 'Limpar conversa',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: Colors.white54),
            tooltip: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Toque no reator, diga "SEXTA-FEIRA" ou digite abaixo para começar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _messages.length,
      itemBuilder: (context, i) => ChatBubble(message: _messages[i]),
    );
  }

  Widget _buildInputBar(Color cyan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Row(
        children: [
          // Botão para esconder o teclado
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            onPressed: () => setState(() => _showKeyboard = false),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Fale com a SEXTA-FEIRA...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cyan.withValues(alpha: 0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cyan.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cyan),
                ),
              ),
              onSubmitted: (v) => _handleUserInput(v.trim()),
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: _state == FridayState.listening ? Icons.mic : Icons.mic_none,
            color: cyan,
            active: _state == FridayState.listening,
            onTap: _toggleListening,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.send,
            color: cyan,
            onTap: () => _handleUserInput(_inputCtrl.text.trim()),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _RoundIconButton(
      {required this.icon,
      required this.color,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          border:
              Border.all(color: color.withValues(alpha: active ? 0.9 : 0.4)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
