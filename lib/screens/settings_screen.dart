import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _homeAddressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString('user_name') ?? 'senhor';
    _homeAddressCtrl.text = prefs.getString('home_address') ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_name',
      _nameCtrl.text.trim().isEmpty ? 'senhor' : _nameCtrl.text.trim(),
    );
    await prefs.setString(
      'home_address',
      _homeAddressCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context, true);
  }

 @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF35E4E0);
    return Scaffold(
      backgroundColor: const Color(0xFF040A10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Como a Sexta-Feira deve chamar você?',
              style: TextStyle(color: cyan, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: const OutlineInputBorder(),
                hintText: 'ex: senhor, chefe...',
                hintStyle: const TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Endereço de Casa (Protocolo Casa):',
              style: TextStyle(color: cyan, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _homeAddressCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: const OutlineInputBorder(),
                hintText: 'Rua Nº, Cidade/Estado',
                hintStyle: const TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan.withValues(alpha: 0.15),
                  side: const BorderSide(color: cyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Salvar', style: TextStyle(color: cyan)),
              ),
            ), // Fim do botão Salvar
            
            
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.menu_book, color: cyan),
              title: const Text('Manual de Protocolos', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Lista de comandos suportados', style: TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0B1620),
                    title: const Text('Protocolos Operacionais', style: TextStyle(color: cyan)),
                    content: const SingleChildScrollView(
                      child: Text(
                        'COMANDOS BÁSICOS:\n'
                        '- "Horas" / "Data"\n'
                        '- "Ligar/Desligar Lanterna"\n'
                        '- "Nível da bateria"\n'
                        '- "Ativar bluetooth"\n'
                        '- "Tirar foto"\n\n'
                        'NAVEGAÇÃO E AGENDA:\n'
                        '- "Trace uma rota até [Local]"\n'
                        '- "Protocolo Casa"\n'
                        '- "Me lembre de [Compromisso]"\n\n'
                        'MÚSICA E MÍDIA:\n'
                        '- "Tocar [Música/Artista]"\n'
                        '- "Protocolo festa/conforto"\n'
                        '- "Aumentar/Diminuir volume"\n'
                        '- "Volume no máximo"\n\n'
                        'APLICATIVOS E FERRAMENTAS:\n'
                        '- "Abrir [Nome do App]"\n'
                        '- "Abrir carteira"\n'
                        '- "Pesquisar sobre [Tema]"\n'
                        '- "Iniciar/Pausar/Zerar cronômetro"\n'
                        '- "Enviar mensagem" (WhatsApp)',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('FECHAR', style: TextStyle(color: cyan)),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}