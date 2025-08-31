import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection.dart';
import '../utils/firebase_config.dart';

class ConnectionService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static const String _collection = 'connections';

  // Cria uma nova conexão
  static Future<Connection> createConnection(String adminId) async {
    try {
      final pin = Connection.generatePin();
      final connection = Connection(
        pin: pin,
        status: ConnectionStatus.waiting,
        adminId: adminId,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_collection).add(connection.toFirestore());
      
      return connection.copyWith(id: docRef.id);
    } catch (e) {
      print('❌ Erro ao criar conexão: $e');
      rethrow;
    }
  }

  // Busca conexões por admin
  static Stream<List<Connection>> getConnectionsByAdmin(String adminId) {
    return _firestore
        .collection(_collection)
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Connection.fromFirestore(doc))
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt))); // Ordenação local
  }

  // Busca conexão por PIN
  static Future<Connection?> getConnectionByPin(String pin) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('pin', isEqualTo: pin)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Connection.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar conexão por PIN: $e');
      return null;
    }
  }

  // Estabelece conexão (client se conecta)
  static Future<bool> establishConnection(String pin, String clientId) async {
    try {
      print('🔍 Tentando conectar com PIN: $pin');
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('pin', isEqualTo: pin)
          .get();

      print('📊 Documentos encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final status = data['status'] as String?;
        
        print('📋 Status da conexão: $status');
        
        if (status == 'waiting') {
          final docRef = doc.reference;
          await docRef.update({
            'status': 'connected',
            'clientId': clientId,
            'connectedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Conexão estabelecida com sucesso!');
          return true;
        } else {
          print('❌ Conexão não está aguardando (status: $status)');
          return false;
        }
      } else {
        print('❌ Nenhuma conexão encontrada com PIN: $pin');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao estabelecer conexão: $e');
      return false;
    }
  }

  // Cancela uma conexão
  static Future<bool> cancelConnection(String connectionId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(connectionId)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('❌ Erro ao cancelar conexão: $e');
      return false;
    }
  }

  // Remove uma conexão permanentemente
  static Future<bool> deleteConnection(String connectionId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(connectionId)
          .delete();
      return true;
    } catch (e) {
      print('❌ Erro ao deletar conexão: $e');
      return false;
    }
  }

  // Busca conexões ativas (conectadas)
  static Stream<List<Connection>> getActiveConnections() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'connected')
        .orderBy('connectedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Connection.fromFirestore(doc))
            .toList());
  }
}
