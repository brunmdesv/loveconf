import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConfig {
  static FirebaseFirestore? _firestore;
  
  // Inicializa o Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      
      // Configurações do Firestore
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      print('✅ Firebase inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro ao inicializar Firebase: $e');
    }
  }
  
  // Retorna a instância do Firestore
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase não foi inicializado. Chame FirebaseConfig.initialize() primeiro.');
    }
    return _firestore!;
  }
  
  // Cria as coleções necessárias se não existirem
  static Future<void> createCollectionsIfNotExist() async {
    try {
      final firestore = FirebaseConfig.firestore;
      
      // Verifica se a coleção connections existe
      final connectionsSnapshot = await firestore.collection('connections').limit(1).get();
      
      if (connectionsSnapshot.docs.isEmpty) {
        // Cria um documento de exemplo para inicializar a coleção
        await firestore.collection('connections').add({
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'example',
          'pin': '0000',
          'adminId': 'system',
          'clientId': null,
        });
        
        // Remove o documento de exemplo
        final exampleDocs = await firestore.collection('connections').where('status', isEqualTo: 'example').get();
        for (var doc in exampleDocs.docs) {
          await doc.reference.delete();
        }
        
        print('✅ Coleções do Firestore criadas com sucesso!');
      }
      
      // Tenta criar o índice necessário (pode falhar se já existir)
      try {
        await firestore.collection('connections')
            .where('adminId', isEqualTo: 'test')
            .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        print('✅ Índice do Firestore já existe ou foi criado!');
      } catch (e) {
        if (e.toString().contains('FAILED_PRECONDITION') && e.toString().contains('requires an index')) {
          print('⚠️ Índice necessário não encontrado. Crie manualmente no console do Firebase:');
          print('   Campo 1: adminId (Ascending)');
          print('   Campo 2: createdAt (Descending)');
          print('   Ou use o link fornecido no console do app.');
        }
      }
    } catch (e) {
      print('❌ Erro ao criar coleções: $e');
    }
  }
}
