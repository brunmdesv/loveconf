import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/location_record.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// Inicializa o serviço de notificações
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configura notificações locais
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Configura notificações do Firebase
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Obtém o token do dispositivo
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔔 Token de notificação: $token');
        // Aqui você pode salvar o token no Firestore para enviar notificações
      }

      // Configura handlers para notificações em background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Configura handlers para notificações em primeiro plano
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      _isInitialized = true;
      print('✅ Serviço de notificações inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
    }
  }

  /// Mostra uma notificação local
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'location_channel',
      'Localizações',
      channelDescription: 'Notificações sobre localizações capturadas',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Notifica sobre nova localização capturada
  static Future<void> notifyNewLocation(LocationRecord location) async {
    await showLocalNotification(
      title: '📍 Nova Localização Capturada',
      body: 'Localização registrada em ${location.formattedTimestamp}',
      payload: 'location_${location.id}',
    );
  }

  /// Notifica sobre conexão estabelecida
  static Future<void> notifyConnectionEstablished(String pin) async {
    await showLocalNotification(
      title: '🔗 Conexão Estabelecida',
      body: 'Cliente conectado com PIN: $pin',
      payload: 'connection_$pin',
    );
  }

  /// Notifica sobre conexão cancelada
  static Future<void> notifyConnectionCancelled(String pin) async {
    await showLocalNotification(
      title: '❌ Conexão Cancelada',
      body: 'Conexão com PIN $pin foi cancelada',
      payload: 'connection_cancelled_$pin',
    );
  }

  /// Handler para notificações em primeiro plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Notificação recebida em primeiro plano: ${message.notification?.title}');
    
    // Mostra notificação local
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Nova Notificação',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handler para notificações em background
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('🔔 Notificação recebida em background: ${message.notification?.title}');
    
    // Aqui você pode processar a notificação em background
    // Por exemplo, salvar no banco local, atualizar UI, etc.
  }

  /// Handler para quando uma notificação é tocada
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificação tocada: ${response.payload}');
    
    // Aqui você pode navegar para uma tela específica baseada no payload
    // Por exemplo, abrir a tela de localizações ou detalhes
  }

  /// Inscreve em um tópico para receber notificações específicas
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('🔔 Inscrito no tópico: $topic');
  }

  /// Cancela inscrição de um tópico
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('🔔 Cancelada inscrição do tópico: $topic');
  }

  /// Obtém o token atual do dispositivo
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

// Handler global para notificações em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._firebaseMessagingBackgroundHandler(message);
}
