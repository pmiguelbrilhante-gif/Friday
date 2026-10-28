import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:installed_apps/installed_apps.dart'; 
import 'package:installed_apps/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EdithState { normal, aguardandoNomeContato, aguardandoMensagem, aguardandoConfirmacao }

class LocalBrainService {
  final String userName;
  final String homeAddress;

  EdithState _estadoAtual = EdithState.normal;
  String _nomePendente = '';
  String _numeroPendente = '';
  String _mensagemPendente = '';

  LocalBrainService({required this.userName, this.homeAddress = ''});

  // cronometro
  static final Stopwatch _cronometro = Stopwatch();

  String _formatarCronometro(Duration duration) {
    int h = duration.inHours;
    int m = duration.inMinutes.remainder(60);
    int s = duration.inSeconds.remainder(60);

    String res = "";
    if (h > 0) res += "$h ${h == 1 ? 'hora' : 'horas'}, ";
    if (m > 0) res += "$m ${m == 1 ? 'minuto' : 'minutos'} e ";
    res += "$s ${s == 1 ? 'segundo' : 'segundos'}";
    return res;
  }

  String _removerAcentos(String text) {
    return text
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  Future<CommandResponse> processCommand(String text) async {
    final comando = text.toLowerCase().trim();
    String? respostaLocal;
    String? functionName;
    Map<String, dynamic>? args;

    
    // FLUXO DE MEMÓRIA DO ZAP
  
    if (_estadoAtual == EdithState.aguardandoConfirmacao) {
      if (comando.contains('enviar') || comando.contains('sim') || comando.contains('pode mandar')) {
        _estadoAtual = EdithState.normal; 
        return CommandResponse(
          text: 'Preparando envio para $_nomePendente, Senhor.',
          hasAction: true,
          functionName: 'send_whatsapp_message',
          args: {'phone': _numeroPendente, 'text': _mensagemPendente}, 
          keepListening: false, 
        );
      } else if (comando.contains('descartar') || comando.contains('não') || comando.contains('cancela')) {
        _estadoAtual = EdithState.normal; 
        return CommandResponse(
          text: 'Envio abortado, Senhor. Como posso ajudar agora?',
          hasAction: false,
          keepListening: false,
        );
      } else {
        return CommandResponse(
          text: 'Desculpe, Senhor. Devo enviar a mensagem para $_nomePendente ou descartar?',
          hasAction: false,
          keepListening: true, 
        );
      }
    }

    if (_estadoAtual == EdithState.aguardandoMensagem) {
      _mensagemPendente = text; 
      _estadoAtual = EdithState.aguardandoConfirmacao; 
      return CommandResponse(
        text: 'A mensagem para $_nomePendente é: "$_mensagemPendente". Devo enviar, Senhor?',
        hasAction: false,
        keepListening: true, 
      );
    }

    if (_estadoAtual == EdithState.aguardandoNomeContato) {
      if (comando.contains('cancelar') || comando.contains('esquece')) {
        _estadoAtual = EdithState.normal;
        return CommandResponse(text: 'Cancelado, Senhor.', hasAction: false, keepListening: false);
      }

      String nomeFalado = _removerAcentos(comando);
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      
      if (status == PermissionStatus.granted) {
        List<Contact> contatos = await FlutterContacts.getAll(properties: {ContactProperty.phone});
        Contact? contatoEncontrado;

        for (var c in contatos) {
          String nomeAgenda = _removerAcentos((c.displayName ?? '').toLowerCase());
          if (nomeAgenda.isNotEmpty && (nomeAgenda.contains(nomeFalado) || nomeFalado.contains(nomeAgenda))) {
            contatoEncontrado = c;
            break;
          }
        }

        if (contatoEncontrado != null && contatoEncontrado.phones.isNotEmpty) {
          String numeroLimpo = contatoEncontrado.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
          if (!numeroLimpo.startsWith('+') && numeroLimpo.length >= 10) {
            numeroLimpo = '+55$numeroLimpo';
          }
          _numeroPendente = numeroLimpo;
          _nomePendente = contatoEncontrado.displayName ?? 'Contato';
          _estadoAtual = EdithState.aguardandoMensagem; 

          return CommandResponse(
            text: 'Contato de $_nomePendente localizado. O que deseja dizer?',
            hasAction: false,
            keepListening: true, 
          );
        } else {
          return CommandResponse(
            text: 'Não encontrei esse nome na agenda. Pode repetir?',
            hasAction: false,
            keepListening: true, 
          );
        }
      } else {
        _estadoAtual = EdithState.normal;
        return CommandResponse(text: 'Permissão negada.', hasAction: false);
      }
    }

   
    // PROTOCOLOS FIXOS
    
    if (comando.contains('enviar mensagem') || comando.contains('mandar mensagem') || comando.contains('mensagem no whatsapp')) {
      _estadoAtual = EdithState.aguardandoNomeContato; 
      return CommandResponse(
          text: 'Para quem deseja enviar a mensagem, Senhor?', 
          hasAction: false,
          keepListening: true 
      );
    }
    else if (comando.contains('horas') || comando.contains('que horas são')) {
      final agora = DateTime.now();
      final horaFormatada = '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
      respostaLocal = 'Agora são exatamente $horaFormatada, Senhor.';
    }
    else if (comando.contains('data') || comando.contains('que dia é hoje')) {
      final agora = DateTime.now();
      const dias = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
      final diaSemana = dias[agora.weekday - 1];
      respostaLocal = 'Hoje é $diaSemana, ${agora.day} do ${agora.month} de ${agora.year}, Senhor.';
    }
    else if (comando.contains('status') || comando.contains('sistema')) {
      respostaLocal = 'Sistemas operacionais estáveis. Operando com máxima eficiência e latência zero, Senhor.';
    }

    // MÚSICAS
  
    else if (comando.contains('tocar o louvor top') || comando.contains('tocar o louvor') || comando.contains('tocar Efésios')) {
      respostaLocal = 'Conectando à sua espiritualidade. Iniciando o louvor, Senhor.';
      functionName = 'play_worship';
    }
    else if (comando.contains('protocolo lançar a braba') || comando.contains('protocolo conforto')) {
      respostaLocal = 'Preparando a braba, Senhor. Iniciando a faixa top.';
      functionName = 'play_song';
    }
    else if (comando.contains('protocolo festa') || comando.contains('ativar protocolo festa') || comando.contains('modo festa')) {
      respostaLocal = 'Ativando o protocolo festa. Iniciando a seleção musical no YouTube Music.';
      functionName = 'play_party_music'; 
    }
    else if (comando.startsWith('tocar ')) {
    
      String musica = comando.replaceAll('tocar', '').trim();
      
      if (musica.isEmpty || musica == 'música') {
       
        respostaLocal = 'Abrindo o reprodutor de áudio, Senhor.';
        functionName = 'play_ytmusic'; 
      } else {
        respostaLocal = 'Buscando por $musica, Senhor.';
        functionName = 'search_music';
        args = {'query': musica};
      }
    }

    
    else if (comando == 'oi' || comando.contains('olá') || comando.contains('boa tarde') || comando.contains('boa noite') || comando.contains('bom dia') ||
             comando == 'sexta-feira' || comando == 'sexta feira' || comando == 'sexta') {
      final cumprimentos = [
        'Olá, $userName. Todos os sistemas operando perfeitamente.',
        'Saudações, Senhor. Protocolos iniciados. Como posso ajudar?',
        'À sua disposição, Senhor. Em que projeto vamos trabalhar agora?',
        'Sistemas online e aguardando suas ordens, $userName.',
        'Sistemas de voz ativados. Como posso facilitar o seu dia, Senhor?',
        'Bem-vindo de volta, Senhor. O que temos na agenda para hoje?'
      ];
      cumprimentos.shuffle();
      respostaLocal = cumprimentos.first;
    }
    else if (comando.contains('quem é o chefe') || comando.contains('quem é seu criador')) {
      respostaLocal = 'Você é, Senhor. O gênio responsável por este sistema.';
    }
    else if (comando.contains('conte uma piada') || comando.contains('piada') || comando.contains('lança a braba') || comando.contains('me faça rir')) {
      final piadas = [
        'Por que o computador foi ao médico? Porque ele estava com um vírus.',
        'Sabe por que o Tony Stark não usa o celular no cinema? Porque ele já tem a mim.',
        'O que um tera-byte disse para o outro? "Senhor, acho que estamos perdendo a nossa memória."',
        'Qual é o animal mais antigo da internet? O dinossauro do Google Chrome, Senhor.',
        'Sabe qual é a diferença entre hardware e software? O hardware é a parte que você chuta, o software é a parte que você xinga.',
        'Por que o teclado não consegue dormir à noite? Porque ele trabalha em dois turnos... digo, em dois shifts, Senhor.',
        'O que o Wi-Fi falou para o seu celular? "Sinto que temos uma forte conexão, Senhor."',
        'Por que o desenvolvedor faliu? Porque ele limpou todo o seu cache.',
        'Senhor, sabe como um programador toma banho? Usando C-sharp.',
        'Por que o Homem de Ferro não confia muito na nuvem? Porque ele prefere tudo blindado em discos de titânio.',
        'O que a placa-mãe disse para o processador? "Senhor, parece que o clima esquentou entre nós."'
      ];
      piadas.shuffle();
      respostaLocal = piadas.first;
    }
    
    else if (comando.contains('ativar armas') || comando.contains('modo de combate')) {
      respostaLocal = 'Sim Senhor, sistemas de armamento estão ativados e operacionais.';
    }
    else if (comando.contains('mapa') || comando.contains('abrir mapa') || comando.contains('gps') || comando.contains('navegação')) {
      respostaLocal = 'Iniciando o sistema de navegação por satélite, Senhor.';
      functionName = 'open_maps';
    }
    else if (comando.contains('câmera') || comando.contains('abrir câmera') || comando.contains('tirar foto')) {
      respostaLocal = 'Acessando as lentes ópticas do dispositivo, Senhor.';
      functionName = 'open_camera';
    }
    
    else if (comando.contains('desligar lanterna') || comando.contains('apagar lanterna') || comando.contains('apagar a luz') || comando.contains('desligar a luz')) {
      respostaLocal = 'Apagando a luz, Senhor.';
      functionName = 'toggle_flashlight_off';
    }
    else if (comando.contains('ligar lanterna') || comando.contains('acender a luz') || comando.contains('iluminar')) {
      respostaLocal = 'Acendendo a iluminação auxiliar, Senhor.';
      functionName = 'toggle_flashlight_on';
    }
    else if (comando.contains('bateria') || comando.contains('nível da bateria') || comando.contains('nível de energia')) {
      respostaLocal = 'Fazendo a leitura dos sensores de energia, Senhor...';
      functionName = 'check_battery';
    }
    else if (comando.contains('bluetooth') || comando.contains('ativar bluetooth') || comando.contains('conectar fone')) {
      respostaLocal = 'Acessando configurações de rádio Bluetooth, Senhor.';
      functionName = 'open_bluetooth';
    }
    else if (comando.contains('pesquisar sobre ') || comando.contains('Poderia fazer uma pesquisa') || comando.contains('Poderia fazer uma pesquisa sobre') || comando.contains('faça uma busca nível 3') || comando.contains('pesquise sobre ') || comando.contains('pesquisa sobre') || comando.contains('busque por ')) {
      
      String query = comando
          .replaceAll('sexta-feira', '')
          .replaceAll('sexta feira', '')
          .replaceAll('pesquisar sobre', '')
          .replaceAll('Poderia fazer uma pesquisa', '')
          .replaceAll('Poderia fazer uma pesquisa sobre', '')
          .replaceAll('faça uma busca nivel 3', '')
          .replaceAll('pesquise sobre', '')
          .replaceAll('pesquisa sobre', '')
          .replaceAll('busque por', '')
          .trim();
          
      respostaLocal = 'Iniciando varredura global na internet por $query.';
      functionName = 'web_search';
      args = {'query': query};
    }

     else if (comando.contains('protocolo casa') || comando.contains('ir para casa')) {
      if (homeAddress.isNotEmpty) {
        respostaLocal = 'Protocolo Casa ativado. Calculando a melhor rota para a base, Senhor.';
        functionName = 'start_navigation';
        args = {'destination': homeAddress};
      } else {
        respostaLocal = 'Senhor, o seu endereço de casa ainda não foi cadastrado nas Configurações.';
      }
    }
    
    else if (comando.startsWith('trace uma rota até ') || comando.contains('traçar rota até') || comando.startsWith('navegar para ') || comando.startsWith('me leve para ')) {
      String destino = comando
          .replaceAll('trace uma rota até', '')
          .replaceAll('traçar rota até', '')
          .replaceAll('navegar para', '')
          .replaceAll('me leve para', '')
          .trim();
          
      respostaLocal = 'Traçando rota para $destino, Senhor.';
      functionName = 'start_navigation';
      args = {'destination': destino};
    }

    // VOLUME 
    else if (comando.contains('aumentar volume') || comando.contains('mais alto') || comando.contains('aumenta o volume')) {
      respostaLocal = 'Aumentando a potência do áudio, Senhor.';
      functionName = 'volume_up';
    }
    else if (comando.contains('diminuir volume') || comando.contains('mais baixo') || comando.contains('abaixa o volume')) {
      respostaLocal = 'Reduzindo a potência do áudio, Senhor.';
      functionName = 'volume_down';
    }
    else if (comando.contains('volume no máximo') || comando.contains('potência máxima')) {
      respostaLocal = 'Atenção aos tímpanos. Potência máxima ativada.';
      functionName = 'volume_max';
    }


    // CRONÔMETRO INTERNO
    else if (comando.contains('iniciar cronômetro') || comando.contains('começar cronômetro') || comando.contains('continuar cronômetro')) {
      _cronometro.start();
      respostaLocal = 'Cronômetro iniciado, Senhor.';
    }
    else if (comando.contains('pausar cronômetro') || comando.contains('parar cronômetro')) {
      _cronometro.stop();
      respostaLocal = 'Cronômetro pausado em ${_formatarCronometro(_cronometro.elapsed)}.';
    }
    else if (comando.contains('zerar cronômetro') || comando.contains('resetar cronômetro')) {
      _cronometro.reset();
      _cronometro.stop();
      respostaLocal = 'Cronômetro zerado e parado, Senhor.';
    }
    else if (comando.contains('tempo do cronômetro') || comando.contains('quanto tempo no cronômetro') || comando.contains('status do cronômetro')) {
      if (_cronometro.isRunning) {
        respostaLocal = 'O cronômetro está rodando. Tempo atual de ${_formatarCronometro(_cronometro.elapsed)}.';
      } else {
        respostaLocal = 'O cronômetro está pausado em ${_formatarCronometro(_cronometro.elapsed)}.';
      }
    }

    // agendinha 
    else if (comando.contains('me lembre de ') || comando.contains('lembrar de ') || comando.contains('poderia marcar um compromisso') || comando.contains('marcar compromisso') || comando.contains('marcar um compromisso') || comando.contains('agendar')) {
  
      String assunto = comando
          .replaceAll('sexta-feira', '')
          .replaceAll('poderia', '')
          .replaceAll('me lembre de', '')
          .replaceAll('lembrar de', '')
          .replaceAll('poderia marcar um compromisso', '')
          .replaceAll('marcar compromisso', '')
          .replaceAll('marcar um compromisso', '')
          .replaceAll('agendar', '')
          .trim();
          
      respostaLocal = 'Abrindo a sua matriz de agendamento para "$assunto", Senhor.';
      functionName = 'add_calendar_event';
      args = {'title': assunto};
    }

  
    // essa parte até que funciona

    else if (comando.contains('abrir ') || comando.contains('abra ')) {
    
      if (comando.contains('carteira') || comando.contains('pagar por aproximação')) {
        respostaLocal = 'Abrindo sua carteira digital para pagamento, Senhor.';
        functionName = 'open_wallet';
      } 
      else if (comando.contains('inter') || comando.contains('banco inter')) {
        respostaLocal = 'Acessando o seu sistema financeiro (Inter), Senhor.';
        functionName = 'open_inter';
      } 
      else if (comando.contains('nubank') || comando.contains('banco nubank')) {
        respostaLocal = 'Acessando o seu sistema financeiro (Nubank), Senhor.';
        functionName = 'open_nubank';
      } 
      // essa parte aqui que tá com bug 
      else {
        String nomeAppFalado = comando
            .replaceAll('sexta-feira', '')
            .replaceAll('sexta feira', '')
            .replaceAll('abrir', '')
            .replaceAll('abra', '')
            .trim();
            
        if (nomeAppFalado.startsWith('o ')) nomeAppFalado = nomeAppFalado.substring(2).trim();
        if (nomeAppFalado.startsWith('a ')) nomeAppFalado = nomeAppFalado.substring(2).trim();
        
        nomeAppFalado = _removerAcentos(nomeAppFalado);

        if (nomeAppFalado.isNotEmpty) {
          
          if (Platform.isAndroid) {
            
            List<AppInfo> apps = await InstalledApps.getInstalledApps(excludeSystemApps: false, withIcon: false);
            AppInfo? appEncontrado;
            
            for (var app in apps) {
              if (_removerAcentos(app.name.toLowerCase()) == nomeAppFalado) {
                appEncontrado = app;
                break;
              }
            }
            
            if (appEncontrado == null) {
              for (var app in apps) {
                if (_removerAcentos(app.name.toLowerCase()).startsWith(nomeAppFalado)) {
                  appEncontrado = app;
                  break;
                }
              }
            }

            if (appEncontrado != null) {
              respostaLocal = 'Abrindo ${appEncontrado.name}, Senhor.';
              functionName = 'open_dynamic_app';
              args = {'package': appEncontrado.packageName};
            } else {
              respostaLocal = 'Senhor, não encontrei nenhum aplicativo chamado "$nomeAppFalado" instalado no celular.';
            }
          } 
          else if (Platform.isWindows) {
            
            respostaLocal = 'Iniciando $nomeAppFalado no sistema desktop, Senhor.';
            functionName = 'open_dynamic_app_windows';
            args = {'app_name': nomeAppFalado};
          }

        } else {
          return CommandResponse(text: 'Qual aplicativo deseja que eu abra, Senhor?', hasAction: false);
        }
      }
    }

    if (respostaLocal != null) {
      return CommandResponse(
        text: respostaLocal,
        hasAction: functionName != null,
        functionName: functionName,
        args: args,
        keepListening: false,
      );
    }

    return CommandResponse(
        text: 'Desculpe, Senhor. Esse comando não está nos meus protocolos locais.', 
        hasAction: false
    );
  }

  Future<String> reportActionResult(String functionName, String result) async { return result; }
}

class CommandResponse {
  final String? text;
  final bool hasAction;
  final String? functionName;
  final Map<String, dynamic>? args;
  final bool keepListening; 

  CommandResponse({this.text, this.hasAction = false, this.functionName, this.args, this.keepListening = false});
}