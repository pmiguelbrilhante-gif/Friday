# SEXTA-FEIRA (FRIDAY) — Assistente Virtual Mobile

Assistente virtual pessoal desenvolvida em **Flutter**, projetada com foco exclusivo no ecossistema **Android**. O sistema opera com reconhecimento de voz offline, síntese de fala de baixa latência e automação nativa de hardware e aplicativos.


## Arquitetura e Diferenciais Técnicos

* **Reconhecimento de Voz Híbrido:** Utiliza o motor offline **Vosk** (`vosk_flutter`) para escuta contínua da palavra de ativação (*"Sexta-feira"*), alternando dinamicamente para o reconhecedor de fala nativo (`speech_to_text`) na captura de comandos.
* **Síntese de Voz Otimizada:** Implementação direta com `flutter_tts` configurada para resposta imediata e sem atrasos de processamento.
* **Interface Holográfica Reativa:** Painel customizado em `CustomPainter` (`ArcReactor` e `HudBackground`) que altera cor, rotação e pulsação em tempo real conforme o estado do sistema.
* **Automação Nativa Android:** Integração direta com o sistema operacional via `android_intent_plus`, `installed_apps` e `flutter_contacts` sem depender de APIs externas de nuvem.


## Protocolos e Comandos Suportados

### Hardware e Sistema
* `"Horas"` / `"Que dia é hoje"` — Consulta de relógio e calendário local.
* `"Ligar lanterna"` / `"Desligar lanterna"` — Controle direto do flash LED (`torch_light`).
* `"Nível da bateria"` — Leitura em tempo real dos sensores de energia (`battery_plus`).
* `"Ativar bluetooth"` — Acesso rápido às configurações de rádio do aparelho.
* `"Aumentar volume"` / `"Diminuir volume"` / `"Volume no máximo"` — Controle granular de mídia (`flutter_volume_controller`).
* `"Abrir câmera"` — Disparo imediato da câmera nativa.

### Navegação e Agenda
* `"Protocolo Casa"` — Inicia a navegação no Google Maps até o endereço residencial salvo nas configurações.
* `"Trace uma rota até [Destino]"` — Calcula rotas dinâmicas direto no GPS.
* `"Me lembre de [Compromisso]"` — Abre a matriz de eventos do Google Agenda preenchida com o título do compromisso.

### Mídia e Comunicação
* `"Tocar [Música ou Artista]"` — Busca e inicia reprodução automática no YouTube Music.
* `"Protocolo festa"` / `"Protocolo conforto"` / `"Tocar o louvor"` — Atalhos para playlists e faixas predefinidas.
* `"Enviar mensagem"` — Fluxo conversacional por voz que busca o contato na agenda do celular, dita a mensagem, pede confirmação e abre o WhatsApp pronto para envio.

### Aplicativos e Utilitários
* `"Abrir [Nome do App]"` — Varredura dinâmica dos pacotes instalados no Android para abrir qualquer aplicativo pelo nome.
* `"Abrir carteira"` / `"Abrir Inter"` / `"Abrir Nubank"` — Atalhos diretos para sistemas financeiros e pagamento por aproximação.
* `"Pesquisar sobre [Tema]"` — Abre busca direta no navegador padrão.
* `"Iniciar cronômetro"` / `"Pausar cronômetro"` / `"Zerar cronômetro"` — Cronômetro interno gerenciado em memória.


## Estrutura do Projeto

```text
lib/
  main.dart                   # Inicialização, sessão de áudio e roteamento inicial
  screens/
    onboarding_screen.dart    # Tela de apresentação e inicialização de protocolos
    home_screen.dart          # Interface principal, controle de estados e chat
    settings_screen.dart      # Configurações de usuário, endereço e manual
  services/
    local_brain_service.dart  # Processamento de linguagem natural local e fluxos
    action_executor.dart      # Execução de Intents nativas e controle de hardware
    wake_word_service.dart    # Motor híbrido de escuta (Vosk + SpeechToText)
    voice_service.dart        # Controle de síntese de voz (TTS)
  widgets/
    arc_reactor.dart          # Componente gráfico animado do núcleo da IA
    hud_background.dart       # Grade e gradiente holográfico de fundo
    chat_bubble.dart          # Balões de diálogo estilizados