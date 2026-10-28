import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class ActionExecutor {
  static Future<String> executeAction(
      String functionName, Map<String, dynamic>? args) async {
    switch (functionName) {
      
      // COMANDOS
      case 'start_navigation':
        return await _startNavigation(args?['destination'] ?? '');
      case 'open_dynamic_app': 
        return await _openAppByPackage(args?['package'] ?? '', '');
        
      case 'open_dynamic_app_windows': 
        return await _openAppWindows(args?['app_name'] ?? '');

      // CONFIGURAÇÃO DO YTMUSIC
      case 'play_ytmusic':
        return await _openAppByPackage('com.google.android.apps.youtube.music', 'https://music.youtube.com');
      case 'play_party_music':
        return await _openAppByScheme('https://music.youtube.com/watch?v=oB9JIz72BoM&si=SASl3XpeTj1r4AZv', 'https://music.youtube.com/');
      case 'play_worship':
        return await _openAppByScheme('https://music.youtube.com/watch?v=zJOINygRqtQ&si=7yheh7PM3D1OBahf', 'https://music.youtube.com/');
      case 'play_song':
        return await _openAppByScheme('https://music.youtube.com/watch?v=2zPGWGqdfJ8&si=k2Q_nQ5aUOCdiDKO', 'https://music.youtube.com/');
      case 'search_music':
        return await _searchMusic(args?['query'] ?? '');

      case 'send_whatsapp_message':
        return await _sendWhatsAppMessage(args?['phone'] ?? '', args?['text'] ?? '');
      case 'open_wallet':
        return await _openAppByPackage('com.google.android.apps.walletnfcrel', 'https://pay.google.com');
      case 'open_inter':
        return await _openAppByScheme('bancointer://', 'https://bancointer.com.br');
      case 'open_nubank':
        return await _openAppByScheme('nubank://', 'https://nubank.com.br');
      case 'open_maps':
        return await _openAppByScheme('geo:0,0', 'https://maps.google.com');
      case 'open_camera':
        return await _openCamera();

      // COMANDOS DE PESQUISA 
      case 'toggle_flashlight_on':
        return await _toggleFlashlight(true);
      case 'toggle_flashlight_off':
        return await _toggleFlashlight(false);
      case 'check_battery':
        return await _checkBattery();
      case 'open_bluetooth':
        return await _openBluetooth();
      case 'web_search':
        return await _webSearch(args?['query'] ?? '');
      
      // CONTROLES DE VOLUME
      case 'volume_up':
        return await _changeVolume(0.2); 
      case 'volume_down':
        return await _changeVolume(-0.2); 
      case 'volume_max':
        return await _changeVolume(1.0, setAbsolute: true);

      //calendário do google
      case 'add_calendar_event':
        return await _addCalendarEvent(args?['title'] ?? 'Novo Compromisso');


      default:
        throw Exception('Ação $functionName ainda não foi configurada.');
    }
  }

  // ligar e desligar lanterna do celular

  static Future<String> _toggleFlashlight(bool on) async {
    try {
      if (on) {
        await TorchLight.enableTorch();
        return 'Lanterna ativada, Senhor.';
      } else {
        await TorchLight.disableTorch();
        return 'Lanterna desativada, Senhor.';
      }
    } catch (e) {
      return 'Não foi possível acessar a lanterna do dispositivo.';
    }
  }


  static Future<String> _checkBattery() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      return 'Senhor, as baterias estão operando em $level por cento.';
    } catch (e) {
      return 'O sensor de bateria está inacessível no momento.';
    }
  }


  static Future<String> _openBluetooth() async {
    if (Platform.isAndroid) {
      try {
        
        const intent = AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS');
        await intent.launch();
        return 'Abrindo as configurações de rádio, Senhor.';
      } catch (e) {
        return 'Não consegui acessar o módulo Bluetooth.';
      }
    }
    return 'Sistema não suportado.';
  }


  // função pra abrir apps no celular 
  static Future<String> _openAppByPackage(String packageName, String fallbackUrl) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(action: 'android.intent.action.MAIN', category: 'android.intent.category.LAUNCHER', package: packageName);
        await intent.launch();
        return 'Abrindo o aplicativo, Senhor.';
      } catch (e) {
        if (fallbackUrl.isNotEmpty) {
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
          return 'Aplicativo não localizado. Redirecionando.';
        }
        return 'Falha ao tentar abrir este aplicativo específico, Senhor.';
      }
    }
    return 'Sistema não suportado.';
  }


  static Future<String> _openAppByScheme(String scheme, String fallbackUrl) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(action: 'android.intent.action.VIEW', data: scheme);
        await intent.launch();
        return 'Acessando o sistema agora mesmo, Senhor.';
      } catch (e) {
        await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        return 'Aplicativo não encontrado. Abrindo o site.';
      }
    }
    return 'Sistema não suportado.';
  }


  static Future<String> _openCamera() async {
    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(action: 'android.media.action.STILL_IMAGE_CAMERA');
        await intent.launch();
        return 'Acessando as câmeras ópticas, Senhor.';
      } catch (e) {
        return 'Erro ao acessar o hardware da câmera.';
      }
    }
    return 'Função não suportada.';
  }


  static Future<String> _sendWhatsAppMessage(String phone, String text) async {
    if (Platform.isAndroid) {
      try {
        final encodedText = Uri.encodeComponent(text);
        final url = phone.isNotEmpty ? 'whatsapp://send?phone=$phone&text=$encodedText' : 'whatsapp://send?text=$encodedText';
        final intent = AndroidIntent(action: 'android.intent.action.VIEW', data: url);
        await intent.launch();
        return 'Mensagem pronta, Senhor. Escolha o destinatário.';
      } catch (e) {
        return 'Erro ao preparar a mensagem do comunicador, Senhor.';
      }
    }
    return 'Sistema não suportado.';
  }


  static Future<String> _startNavigation(String destination) async {
    if (Platform.isAndroid) {
      try {
        final url = 'google.navigation:q=${Uri.encodeComponent(destination)}';
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: url,
          package: 'com.google.android.apps.maps', 
        );
        await intent.launch();
        return 'Calculando rota para o destino, Senhor.';
      } catch (e) {
        return 'Erro ao abrir o sistema de navegação satelital.';
      }
    } else if (Platform.isWindows) {
     
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}';
      await Process.run('cmd', ['/c', 'start', 'chrome', url]);
      return 'Calculando rota no painel de navegação, Senhor.';
    }
    return 'Sistema não suportado.';
  }

  static Future<String> _searchMusic(String query) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.media.action.MEDIA_PLAY_FROM_SEARCH',
          arguments: {'query': query},
          package: 'com.google.android.apps.youtube.music',
        );
        await intent.launch();
        return 'Iniciando reprodução da faixa musical, Senhor.';
      } catch (e) {
        final fallbackUrl = 'https://music.youtube.com/search?q=${Uri.encodeComponent(query)}';
        await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        return 'Pesquisando a música, Senhor.';
      }
    } else if (Platform.isWindows) {
      
      try {
        final url = 'https://music.youtube.com/search?q=${Uri.encodeComponent(query)}';
        await Process.run('cmd', ['/c', 'start', 'chrome', url]);
        return 'Iniciando a busca no YouTube Music via navegador, Senhor.';
      } catch (e) {
        return 'Não consegui acessar o navegador do computador.';
      }
    }
    return 'Sistema não suportado.';
  }

  static Future<String> _webSearch(String query) async {
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    
    if (Platform.isAndroid) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return 'Aqui está o resultado da busca na rede global, Senhor.';
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', 'chrome', url]);
      return 'Pesquisa iniciada nos terminais do Chrome, Senhor.';
    }
    return 'Sistema não suportado.';
  }

  static Future<String> _openAppWindows(String appName) async {
    try {
      
      await Process.run('cmd', ['/c', 'start', appName]);
      return 'Processo iniciado no computador, Senhor.';
    } catch (e) {
      return 'Não consegui localizar este programa no Windows.';
    }
  }


  static Future<String> _changeVolume(double change, {bool setAbsolute = false}) async {
    try {
      if (setAbsolute) {
        await FlutterVolumeController.setVolume(change);
        return 'Volume ajustado, Senhor.';
      } else {
        
        double? current = await FlutterVolumeController.getVolume();
        double newVolume = ((current ?? 0.5) + change).clamp(0.0, 1.0);
        
        await FlutterVolumeController.setVolume(newVolume);
        return 'Volume ajustado, Senhor.';
      }
    } catch (e) {
      return 'Não foi possível acessar o controle de volume.';
    }
  }


  static Future<String> _addCalendarEvent(String title) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.INSERT',
          data: 'content://com.android.calendar/events',
          arguments: {
            'title': title,
          },
        );
        await intent.launch();
        return 'Matriz de agendamento aberta. Por favor, confirme a data e horário, Senhor.';
      } catch (e) {
        return 'Erro ao acessar o calendário do sistema.';
      }
    }
    return 'Sistema não suportado.';
  }
}