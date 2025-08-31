import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus {
  waiting,
  connected,
  cancelled,
}

class Connection {
  final String? id;
  final String pin;
  final ConnectionStatus status;
  final String adminId;
  final String? clientId;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? cancelledAt;

  Connection({
    this.id,
    required this.pin,
    required this.status,
    required this.adminId,
    this.clientId,
    required this.createdAt,
    this.connectedAt,
    this.cancelledAt,
  });

  // Converte Firestore para objeto
  factory Connection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Connection(
      id: doc.id,
      pin: data['pin'] ?? '',
      status: ConnectionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ConnectionStatus.waiting,
      ),
      adminId: data['adminId'] ?? '',
      clientId: data['clientId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      connectedAt: data['connectedAt'] != null 
          ? (data['connectedAt'] as Timestamp).toDate() 
          : null,
      cancelledAt: data['cancelledAt'] != null 
          ? (data['cancelledAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Converte objeto para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'pin': pin,
      'status': status.toString().split('.').last,
      'adminId': adminId,
      'clientId': clientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'connectedAt': connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // Cria uma cópia com alterações
  Connection copyWith({
    String? id,
    String? pin,
    ConnectionStatus? status,
    String? adminId,
    String? clientId,
    DateTime? createdAt,
    DateTime? connectedAt,
    DateTime? cancelledAt,
  }) {
    return Connection(
      id: id ?? this.id,
      pin: pin ?? this.pin,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      connectedAt: connectedAt ?? this.connectedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  // Gera um PIN aleatório de 4 dígitos
  static String generatePin() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final pin = (random % 9000 + 1000).toString();
    return pin;
  }

  // Formata a data para exibição
  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedConnectedAt {
    if (connectedAt == null) return '';
    return '${connectedAt!.day.toString().padLeft(2, '0')}/${connectedAt!.month.toString().padLeft(2, '0')}/${connectedAt!.year} ${connectedAt!.hour.toString().padLeft(2, '0')}:${connectedAt!.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case ConnectionStatus.waiting:
        return 'Aguardando conexão';
      case ConnectionStatus.connected:
        return 'Conectado';
      case ConnectionStatus.cancelled:
        return 'Cancelado';
    }
  }

  bool get canBeCancelled {
    return status == ConnectionStatus.waiting || status == ConnectionStatus.connected;
  }
}
