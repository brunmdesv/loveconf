import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Solicita permissão de notificação
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      
      switch (status) {
        case PermissionStatus.granted:
          print('✅ Permissão de notificação concedida');
          return true;
        case PermissionStatus.denied:
          print('❌ Permissão de notificação negada');
          return false;
        case PermissionStatus.permanentlyDenied:
          print('❌ Permissão de notificação negada permanentemente');
          // Abre as configurações do app para o usuário
          await openAppSettings();
          return false;
        default:
          return false;
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissão: $e');
      return false;
    }
  }

  // Verifica se a permissão foi concedida
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('❌ Erro ao verificar permissão: $e');
      return false;
    }
  }

  // Verifica o status atual da permissão
  static Future<PermissionStatus> getNotificationPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } catch (e) {
      print('❌ Erro ao obter status da permissão: $e');
      return PermissionStatus.denied;
    }
  }
}
