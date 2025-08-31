import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_service.dart';

class AppInitializationService {
  static const String _firstRunKey = 'first_run';
  static const String _permissionsRequestedKey = 'permissions_requested';

  /// Verifica se é a primeira execução do app
  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunKey) ?? true;
  }

  /// Marca que o app já foi executado
  static Future<void> markAsNotFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, false);
  }

  /// Verifica se as permissões já foram solicitadas
  static Future<bool> werePermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  /// Marca que as permissões foram solicitadas
  static Future<void> markPermissionsAsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  /// Inicializa o app, solicitando permissões se necessário
  static Future<void> initializeApp(BuildContext context) async {
    try {
      // Verifica se é a primeira execução
      final isFirstRun = await AppInitializationService.isFirstRun();
      
      if (isFirstRun) {
        print('🚀 Primeira execução do app detectada');
        
        // Marca que não é mais a primeira execução
        await markAsNotFirstRun();
        
        // Verifica se as permissões já foram solicitadas
        final permissionsRequested = await werePermissionsRequested();
        
        if (!permissionsRequested) {
          print('🔐 Solicitando permissões na primeira execução');
          
          // Aguarda um pouco para o app carregar completamente
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Solicita permissões de notificação
          final granted = await PermissionService.requestNotificationPermission();
          
          // Marca que as permissões foram solicitadas
          await markPermissionsAsRequested();
          
          if (granted) {
            print('✅ Permissões concedidas na primeira execução');
            _showPermissionsGrantedSnackBar(context);
          } else {
            print('⚠️ Permissões negadas na primeira execução');
            _showPermissionsDeniedSnackBar(context);
          }
        }
      } else {
        print('🔄 App já foi executado anteriormente');
        
        // Verifica se as permissões foram solicitadas
        final permissionsRequested = await werePermissionsRequested();
        
        if (!permissionsRequested) {
          print('🔐 Permissões ainda não foram solicitadas, solicitando agora');
          
          // Aguarda um pouco para o app carregar completamente
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Solicita permissões de notificação
          final granted = await PermissionService.requestNotificationPermission();
          
          // Marca que as permissões foram solicitadas
          await markPermissionsAsRequested();
          
          if (granted) {
            print('✅ Permissões concedidas');
            _showPermissionsGrantedSnackBar(context);
          } else {
            print('⚠️ Permissões negadas');
            _showPermissionsDeniedSnackBar(context);
          }
        } else {
          print('✅ Permissões já foram solicitadas anteriormente');
        }
      }
    } catch (e) {
      print('❌ Erro durante a inicialização do app: $e');
    }
  }

  /// Mostra SnackBar informando que as permissões foram concedidas
  static void _showPermissionsGrantedSnackBar(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Permissões de notificação ativadas!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Mostra SnackBar informando que as permissões foram negadas
  static void _showPermissionsDeniedSnackBar(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Permissões de notificação negadas. Você pode ativá-las nas configurações do app.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
