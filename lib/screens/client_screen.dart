import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../services/connection_service.dart';
import '../services/app_state_service.dart';
import '../models/connection.dart';
import '../widgets/gradient_button.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  String? _activeConnectionPin;
  DateTime? _connectionDate;
  final TextEditingController _pinController = TextEditingController();
  String? _clientId;

  @override
  void initState() {
    super.initState();
    print('🚀 initState chamado');
    print('🔍 _isLoading inicial: $_isLoading');
    
    // Garante que _isLoading seja false no início
    setState(() {
      _isLoading = false;
    });
    print('🔍 _isLoading após setState: $_isLoading');
    
    _initializeClient();
    
    // Verifica o status da conexão periodicamente
    _startConnectionStatusCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 didChangeDependencies chamado');
    print('🔍 _isLoading em didChangeDependencies: $_isLoading');
    
    // Garante que _isLoading seja false quando a tela é focada
    if (_isLoading) {
      print('🔄 Resetando _isLoading em didChangeDependencies');
      setState(() {
        _isLoading = false;
      });
      print('🔍 _isLoading após reset: $_isLoading');
    }
  }

  void _startConnectionStatusCheck() {
    print('⏰ _startConnectionStatusCheck() chamado');
    print('🔍 _isLoading em _startConnectionStatusCheck: $_isLoading');
    // Verifica o status a cada 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isConnected && _activeConnectionPin != null) {
        print('⏰ Verificação periódica executada');
        _checkConnectionStatus();
        _startConnectionStatusCheck(); // Continua verificando
      } else {
        print('⏰ Verificação periódica parada: mounted=$mounted, _isConnected=$_isConnected, _activeConnectionPin=$_activeConnectionPin');
      }
    });
  }

  Future<void> _initializeClient() async {
    print('🚀 _initializeClient() chamado');
    print('🔍 _isLoading no início de _initializeClient: $_isLoading');
    
    // Inicializa o ID do cliente
    final clientId = await AppStateService.getOrCreateClientId();
    print('🔑 Client ID obtido: $clientId');
    setState(() {
      _clientId = clientId;
    });
    print('🔍 _isLoading após setState do clientId: $_isLoading');

    // Verifica se há uma conexão ativa
    if (AppStateService.hasActiveConnection) {
      print('🔗 Conexão ativa encontrada no AppState');
      final connectionData = AppStateService.activeConnectionData;
      if (connectionData != null) {
        print('🔗 Dados da conexão: $connectionData');
        
        // Verifica se a conexão ainda está ativa no Firestore antes de restaurar
        try {
          final snapshot = await ConnectionService.getConnectionByPinAnyStatus(connectionData['pin']);
          if (snapshot != null && snapshot.status == ConnectionStatus.connected) {
            setState(() {
              _isConnected = true;
              _activeConnectionPin = connectionData['pin'];
              _connectionDate = connectionData['date'];
            });
            print('✅ Estado restaurado como conectado');
          } else {
            print('⚠️ Conexão no AppState não está mais ativa no Firestore');
            await AppStateService.clearActiveConnection();
            _clearScreenState();
            print('✅ Estado limpo - conexão não está mais ativa');
          }
        } catch (e) {
          print('❌ Erro ao verificar conexão no Firestore: $e');
          // Em caso de erro, limpa o estado
          await AppStateService.clearActiveConnection();
          _clearScreenState();
        }
      }
    } else {
      print('🔗 Nenhuma conexão ativa no AppState');
    }

    print('🔍 _isLoading no final de _initializeClient: $_isLoading');
    print('✅ _initializeClient() concluído');
  }

  // Verifica se a conexão ainda está ativa no Firestore
  Future<void> _checkConnectionStatus() async {
    print('🔍 _checkConnectionStatus() chamado');
    print('🔍 _isLoading em _checkConnectionStatus: $_isLoading');
    if (_activeConnectionPin != null && _isConnected) {
      print('🔍 Verificando conexão com PIN: $_activeConnectionPin');
      try {
        // Busca a conexão por PIN sem filtrar por status
        final snapshot = await ConnectionService.getConnectionByPinAnyStatus(_activeConnectionPin!);
        print('🔍 Status da conexão: ${snapshot?.statusText ?? "não encontrada"}');
        
        if (snapshot == null || snapshot.status != ConnectionStatus.connected) {
          // Conexão foi cancelada, desconectada ou não existe mais
          print('🔄 Status da conexão mudou: ${snapshot?.statusText ?? "não encontrada"}');
          await AppStateService.clearActiveConnection();
          _clearScreenState();
          print('✅ Estado resetado para desconectado');
          
          // Mostra mensagem informativa para o usuário
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  snapshot?.status == ConnectionStatus.cancelled 
                      ? AppConstants.connectionCancelledByAdmin
                      : AppConstants.connectionNotActive
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('✅ Conexão ainda está ativa');
        }
      } catch (e) {
        print('❌ Erro ao verificar status da conexão: $e');
      }
    } else {
      print('🔍 Nenhum PIN ativo ou não está conectado para verificar');
    }
  }

  @override
  void dispose() {
    print('🧹 dispose chamado');
    print('🔍 _isLoading em dispose: $_isLoading');
    _pinController.dispose();
    // Limpa o estado ao sair da tela
    _isLoading = false;
    print('🔍 _isLoading após limpar em dispose: $_isLoading');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.clientTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.clientAreaTitle,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.clientSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),



                // Campo de PIN ou Card de Conexão Ativa
                if (!_isConnected) ...[
                  // Campo de PIN
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: TextField(
                      controller: _pinController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Digite o PIN de 4 dígitos',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        hintText: '0000',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.accentColor,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.accentColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                                     // Botão Conectar
                   Padding(
                     padding: const EdgeInsets.only(bottom: 24),
                     child: GradientButton(
                       text: _isLoading ? 'Conectando...' : 'Conectar',
                       onPressed: () {
                         print('🚀 Botão Conectar clicado!');
                         print('🔍 PIN no controller: "${_pinController.text}"');
                         print('🔍 PIN length: ${_pinController.text.length}');
                         print('🔍 _isLoading: $_isLoading');
                         
                         if (_isLoading) {
                           print('⚠️ Botão clicado mas _isLoading é true');
                           return;
                         }
                         
                         if (_pinController.text.length != 4) {
                           print('⚠️ PIN inválido, length: ${_pinController.text.length}');
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                               content: Text('Digite um PIN válido de 4 dígitos'),
                               backgroundColor: Colors.orange,
                             ),
                           );
                           return;
                         }
                         
                         print('✅ Chamando _connectToAdmin()');
                         _connectToAdmin();
                       },
                       icon: _isLoading ? Icons.hourglass_empty : Icons.link,
                       width: double.infinity,
                     ),
                   ),
                ] else ...[
                  // Card de Conexão Ativa
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Conexão Ativa',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'PIN: $_activeConnectionPin',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_connectionDate != null)
                              Text(
                                'Conectado em: ${_formatDate(_connectionDate!)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Apenas o Admin pode desconectar esta conexão',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],


              ],
            ),
          ),
        ),
      ),
    );
  }



    // Conecta ao admin usando o PIN
  Future<void> _connectToAdmin() async {
    print('🚀 _connectToAdmin() chamado!');
    print('🔍 PIN digitado: "${_pinController.text}"');
    print('🔍 PIN length: ${_pinController.text.length}');
    
    final pin = _pinController.text.trim();
    print('🔍 PIN após trim: "$pin"');
    print('🔍 PIN após trim length: ${pin.length}');
    
    if (pin.length != 4) {
      print('❌ PIN inválido: $pin (length: ${pin.length})');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um PIN válido de 4 dígitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🔍 Tentando conectar com PIN: $pin');
    
    // Garante que o estado seja limpo antes de começar
    if (_isLoading) {
      print('⚠️ _isLoading já estava true, resetando...');
      setState(() {
        _isLoading = false;
      });
      print('🔍 _isLoading após reset: $_isLoading');
    }
    
    print('🔍 _isLoading antes de definir como true: $_isLoading');
    setState(() {
      _isLoading = true;
    });
    print('✅ _isLoading definido como true');
    print('🔍 _isLoading após definir como true: $_isLoading');

    try {
      print('🔑 _clientId: $_clientId');
      if (_clientId == null) {
        print('❌ _clientId é null!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID do cliente não foi inicializado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final success = await ConnectionService.establishConnection(
        pin,
        _clientId!,
      );

      print('📱 Resultado da conexão: $success');

      if (mounted) {
        if (success) {
          // Salva o estado da conexão
          await AppStateService.setActiveConnection('temp_${DateTime.now().millisecondsSinceEpoch}', pin);
          
          setState(() {
            _isConnected = true;
            _activeConnectionPin = pin;
            _connectionDate = DateTime.now();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.connectionEstablished),
              backgroundColor: AppTheme.accentColor,
            ),
          );
          _pinController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.invalidPin),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro na conexão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.connectError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('🔄 Finally executado, resetando _isLoading');
      print('🔍 _isLoading antes de resetar: $_isLoading');
      setState(() {
        _isLoading = false;
      });
      print('✅ _isLoading resetado para false');
      print('🔍 _isLoading após resetar: $_isLoading');
    }
  }



  // Formata a data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Limpa o estado da tela
  void _clearScreenState() {
    print('🧹 _clearScreenState chamado');
    print('🔍 _isLoading antes de limpar: $_isLoading');
    setState(() {
      _isConnected = false;
      _activeConnectionPin = null;
      _connectionDate = null;
      _isLoading = false;
    });
    print('🔍 _isLoading após limpar: $_isLoading');
    _pinController.clear();
    print('🧹 Estado da tela limpo');
  }
}
