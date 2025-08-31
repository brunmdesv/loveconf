import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_record.dart';
import 'notification_service.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'locations';
  
  // Stream controller para atualizações em tempo real
  static final StreamController<List<LocationRecord>> _locationsController = 
      StreamController<List<LocationRecord>>.broadcast();
  
  static Stream<List<LocationRecord>> get locationsStream => _locationsController.stream;

  /// Verifica se as permissões de localização estão concedidas
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('❌ Erro ao verificar permissões de localização: $e');
      return false;
    }
  }

  /// Solicita permissões de localização
  static Future<bool> requestLocationPermission() async {
    try {
      print('🔐 Solicitando permissões de localização...');
      
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Serviço de localização desabilitado');
        return false;
      }

      // Verifica permissões atuais
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('🔐 Permissão negada, solicitando...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permissão negada pelo usuário');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permissão negada permanentemente');
        return false;
      }

      // Solicita permissão de localização em background
      if (permission == LocationPermission.whileInUse) {
        print('🔐 Solicitando permissão de localização em background...');
        permission = await Geolocator.requestPermission();
      }

      print('✅ Permissões de localização concedidas: $permission');
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('❌ Erro ao solicitar permissões de localização: $e');
      return false;
    }
  }

  /// Captura a localização atual do dispositivo
  static Future<LocationRecord?> captureCurrentLocation({
    required String clientId,
    required String adminId,
    String? connectionPin,
  }) async {
    try {
      print('📍 Capturando localização atual...');
      
      // Verifica permissões
      if (!await hasLocationPermission()) {
        print('❌ Sem permissões de localização');
        return null;
      }

      // Captura a posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Localização capturada: ${position.latitude}, ${position.longitude}');

      // Tenta obter o endereço
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}, ${place.subLocality}, ${place.locality}';
          print('📍 Endereço obtido: $address');
        }
      } catch (e) {
        print('⚠️ Erro ao obter endereço: $e');
      }

      // Cria o registro de localização
      LocationRecord locationRecord = LocationRecord.fromCurrentLocation(
        clientId: clientId,
        adminId: adminId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        connectionPin: connectionPin,
      );

             // Salva no Firestore
       await saveLocationRecord(locationRecord);
       
       // Notifica sobre a nova localização
       await NotificationService.notifyNewLocation(locationRecord);
       
       print('✅ Localização salva com sucesso');
       return locationRecord;
    } catch (e) {
      print('❌ Erro ao capturar localização: $e');
      return null;
    }
  }

  /// Salva um registro de localização no Firestore
  static Future<void> saveLocationRecord(LocationRecord record) async {
    try {
      print('💾 Salvando localização no Firestore...');
      
      await _firestore
          .collection(_collectionName)
          .doc(record.id)
          .set(record.toMap());
      
      print('✅ Localização salva no Firestore');
      
      // Notifica os listeners sobre a nova localização
      _notifyLocationUpdate();
    } catch (e) {
      print('❌ Erro ao salvar localização no Firestore: $e');
      rethrow;
    }
  }

  /// Busca todas as localizações de um cliente
  static Future<List<LocationRecord>> getClientLocations(String clientId) async {
    try {
      print('🔍 Buscando localizações do cliente: $clientId');
      
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      List<LocationRecord> locations = snapshot.docs
          .map((doc) => LocationRecord.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ ${locations.length} localizações encontradas');
      return locations;
    } catch (e) {
      print('❌ Erro ao buscar localizações: $e');
      return [];
    }
  }

  /// Busca todas as localizações de um admin
  static Future<List<LocationRecord>> getAdminLocations(String adminId) async {
    try {
      print('🔍 Buscando localizações do admin: $adminId');
      
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('adminId', isEqualTo: adminId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      List<LocationRecord> locations = snapshot.docs
          .map((doc) => LocationRecord.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ ${locations.length} localizações encontradas');
      return locations;
    } catch (e) {
      print('❌ Erro ao buscar localizações: $e');
      return [];
    }
  }

  /// Busca localizações por PIN de conexão
  static Future<List<LocationRecord>> getLocationsByPin(String pin) async {
    try {
      print('🔍 Buscando localizações por PIN: $pin');
      
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('connectionPin', isEqualTo: pin)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      List<LocationRecord> locations = snapshot.docs
          .map((doc) => LocationRecord.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Ordena por timestamp mais recente primeiro
      locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ ${locations.length} localizações encontradas para PIN $pin');
      return locations;
    } catch (e) {
      print('❌ Erro ao buscar localizações por PIN: $e');
      // Em caso de erro de índice, tenta buscar sem ordenação
      try {
        QuerySnapshot snapshot = await _firestore
            .collection(_collectionName)
            .where('connectionPin', isEqualTo: pin)
            .where('isActive', isEqualTo: true)
            .get();

        List<LocationRecord> locations = snapshot.docs
            .map((doc) => LocationRecord.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Ordena localmente
        locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        print('✅ ${locations.length} localizações encontradas para PIN $pin (sem ordenação do Firestore)');
        return locations;
      } catch (e2) {
        print('❌ Erro ao buscar localizações sem ordenação: $e2');
        return [];
      }
    }
  }

  /// Busca a localização mais recente de um cliente
  static Future<LocationRecord?> getLatestClientLocation(String clientId) async {
    try {
      print('🔍 Buscando localização mais recente do cliente: $clientId');
      
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        LocationRecord location = LocationRecord.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>
        );
        print('✅ Localização mais recente encontrada: ${location.coordinatesText}');
        return location;
      }

      print('⚠️ Nenhuma localização encontrada para o cliente');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar localização mais recente: $e');
      return null;
    }
  }

  /// Marca uma localização como inativa
  static Future<void> deactivateLocation(String locationId) async {
    try {
      print('🗑️ Desativando localização: $locationId');
      
      await _firestore
          .collection(_collectionName)
          .doc(locationId)
          .update({'isActive': false});
      
      print('✅ Localização desativada');
      
      // Notifica os listeners sobre a atualização
      _notifyLocationUpdate();
    } catch (e) {
      print('❌ Erro ao desativar localização: $e');
      rethrow;
    }
  }

  /// Inicia monitoramento de localizações em tempo real
  static Stream<List<LocationRecord>> startLocationMonitoring({
    String? clientId,
    String? adminId,
    String? connectionPin,
  }) {
    print('📡 Iniciando monitoramento de localizações...');
    
    Query query = _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true);

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    
    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    
    if (connectionPin != null) {
      query = query.where('connectionPin', isEqualTo: connectionPin);
    }

    return query.snapshots().map((snapshot) {
      List<LocationRecord> locations = snapshot.docs
          .map((doc) => LocationRecord.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      print('📡 ${locations.length} localizações atualizadas em tempo real');
      return locations;
    });
  }

  /// Notifica os listeners sobre atualizações
  static void _notifyLocationUpdate() {
    // Esta função pode ser expandida para notificar outros serviços
    print('📢 Notificando atualização de localizações');
  }

  /// Calcula a distância entre duas coordenadas
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Verifica se o serviço de localização está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtém a última localização conhecida
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('❌ Erro ao obter última posição conhecida: $e');
      return null;
    }
  }

  /// Dispara o serviço de localização
  static Future<void> dispose() async {
    await _locationsController.close();
  }
}
