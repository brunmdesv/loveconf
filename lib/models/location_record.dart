import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationRecord {
  final String id;
  final String clientId;
  final String adminId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final String? connectionPin;
  final bool isActive;
  final Map<String, dynamic>? deviceInfo;

  LocationRecord({
    required this.id,
    required this.clientId,
    required this.adminId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.connectionPin,
    this.isActive = true,
    this.deviceInfo,
  });

  // Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'adminId': adminId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'connectionPin': connectionPin,
      'isActive': isActive,
      'deviceInfo': deviceInfo,
    };
  }

  // Cria um LocationRecord a partir de um Map do Firestore
  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      adminId: map['adminId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      connectionPin: map['connectionPin'],
      isActive: map['isActive'] ?? true,
      deviceInfo: map['deviceInfo'] != null ? Map<String, dynamic>.from(map['deviceInfo']) : null,
    );
  }

  // Cria um LocationRecord a partir de coordenadas atuais
  factory LocationRecord.fromCurrentLocation({
    required String clientId,
    required String adminId,
    required double latitude,
    required double longitude,
    String? address,
    String? connectionPin,
    Map<String, dynamic>? deviceInfo,
  }) {
    return LocationRecord(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      adminId: adminId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: DateTime.now(),
      connectionPin: connectionPin,
      isActive: true,
      deviceInfo: deviceInfo,
    );
  }

  // Formata as coordenadas para exibição
  String get coordinatesText => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  // Formata o timestamp para exibição
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  // Formata o timestamp completo
  String get fullTimestamp {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} às ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Calcula a distância entre duas localizações (em metros)
  double distanceTo(LocationRecord other) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = latitude * (pi / 180);
    final lat2Rad = other.latitude * (pi / 180);
    final deltaLat = (other.latitude - latitude) * (pi / 180);
    final deltaLon = (other.longitude - longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Verifica se a localização é recente (últimos 5 minutos)
  bool get isRecent {
    final difference = DateTime.now().difference(timestamp);
    return difference.inMinutes < 5;
  }

  // Verifica se a localização é hoje
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }
}
