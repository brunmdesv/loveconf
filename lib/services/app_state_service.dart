import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const String _adminIdKey = 'admin_id';
  static const String _clientIdKey = 'client_id';
  static const String _activeConnectionKey = 'active_connection';
  static const String _activeConnectionPinKey = 'active_connection_pin';
  static const String _connectionDateKey = 'connection_date';
  
  static String? _adminId;
  static String? _clientId;
  static String? _activeConnection;
  static String? _activeConnectionPin;
  static DateTime? _connectionDate;

  // Inicializa o serviço
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _adminId = prefs.getString(_adminIdKey);
    _clientId = prefs.getString(_clientIdKey);
    _activeConnection = prefs.getString(_activeConnectionKey);
    _activeConnectionPin = prefs.getString(_activeConnectionPinKey);
    
    final connectionDateString = prefs.getString(_connectionDateKey);
    if (connectionDateString != null) {
      _connectionDate = DateTime.tryParse(connectionDateString);
    }
  }

  // Gera e salva um ID de admin
  static Future<String> getOrCreateAdminId() async {
    if (_adminId == null) {
      _adminId = 'admin_${DateTime.now().millisecondsSinceEpoch}';
      await _saveAdminId();
    }
    return _adminId!;
  }

  // Gera e salva um ID de cliente
  static Future<String> getOrCreateClientId() async {
    if (_clientId == null) {
      _clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      await _saveClientId();
    }
    return _clientId!;
  }

  // Salva o ID do admin
  static Future<void> _saveAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminIdKey, _adminId!);
  }

  // Salva o ID do cliente
  static Future<void> _saveClientId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientIdKey, _clientId!);
  }

  // Define uma conexão ativa
  static Future<void> setActiveConnection(String connectionId, String pin) async {
    _activeConnection = connectionId;
    _activeConnectionPin = pin;
    _connectionDate = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeConnectionKey, connectionId);
    await prefs.setString(_activeConnectionPinKey, pin);
    await prefs.setString(_connectionDateKey, _connectionDate!.toIso8601String());
  }

  // Remove a conexão ativa
  static Future<void> clearActiveConnection() async {
    _activeConnection = null;
    _activeConnectionPin = null;
    _connectionDate = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeConnectionKey);
    await prefs.remove(_activeConnectionPinKey);
    await prefs.remove(_connectionDateKey);
  }

  // Verifica se há uma conexão ativa
  static bool get hasActiveConnection => _activeConnection != null;

  // Retorna os dados da conexão ativa
  static Map<String, dynamic>? get activeConnectionData {
    if (_activeConnection == null) return null;
    
    return {
      'id': _activeConnection,
      'pin': _activeConnectionPin,
      'date': _connectionDate,
    };
  }

  // Limpa todos os dados (logout)
  static Future<void> clearAllData() async {
    _adminId = null;
    _clientId = null;
    _activeConnection = null;
    _activeConnectionPin = null;
    _connectionDate = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
