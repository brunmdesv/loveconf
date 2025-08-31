import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../services/permission_service.dart';
import '../services/connection_service.dart';
import '../services/app_state_service.dart';
import '../widgets/gradient_button.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  bool _isLoading = false;
  bool _permissionsGranted = false;
  bool _isConnected = false;
  String? _activeConnectionId;
  String? _activeConnectionPin;
  DateTime? _connectionDate;
  final TextEditingController _pinController = TextEditingController();
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    // Inicializa o ID do cliente
    final clientId = await AppStateService.getOrCreateClientId();
    setState(() {
      _clientId = clientId;
    });

    // Verifica se há uma conexão ativa
    if (AppStateService.hasActiveConnection) {
      final connectionData = AppStateService.activeConnectionData;
      if (connectionData != null) {
        setState(() {
          _isConnected = true;
          _activeConnectionId = connectionData['id'];
          _activeConnectionPin = connectionData['pin'];
          _connectionDate = connectionData['date'];
        });
      }
    }

    // Verifica permissões
    await _checkPermissions();
  }

  @override
  void dispose() {
    _pinController.dispose();
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
                        width: 80,
                        height: 80,
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
                          size: 40,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.clientAreaTitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.clientSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Botão de Permissões
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GradientButton(
                    text: _permissionsGranted ? AppConstants.permissionsActive : 'Ativar Permissões',
                    onPressed: _permissionsGranted ? () {} : () => _requestPermissions(),
                    icon: _permissionsGranted ? Icons.check_circle : Icons.notifications_active,
                    width: double.infinity,
                    isOutlined: _permissionsGranted,
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
                      text: 'Conectar',
                      onPressed: _isLoading || _pinController.text.length != 4 
                          ? () {} 
                          : () => _connectToAdmin(),
                      icon: Icons.link,
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
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _disconnect(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.withValues(alpha: 0.7)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.link_off,
                                      color: Colors.red.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Desconectar',
                                      style: TextStyle(
                                        color: Colors.red.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Status das permissões
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _permissionsGranted ? Icons.check_circle : Icons.info,
                            size: 32,
                            color: _permissionsGranted ? AppTheme.accentColor : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _permissionsGranted ? AppConstants.permissionsActive : AppConstants.permissionsPending,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _permissionsGranted 
                                      ? AppConstants.permissionsDescription
                                      : AppConstants.permissionsRequest,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Verifica o status das permissões
  Future<void> _checkPermissions() async {
    final granted = await PermissionService.isNotificationPermissionGranted();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  // Solicita permissões
  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestNotificationPermission();
    setState(() {
      _permissionsGranted = granted;
    });

    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.permissionsGranted),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.permissionsDenied),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

    // Conecta ao admin usando o PIN
  Future<void> _connectToAdmin() async {
    final pin = _pinController.text.trim();
    
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um PIN válido de 4 dígitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🔍 Tentando conectar com PIN: $pin');
    
    setState(() {
      _isLoading = true;
    });

    try {
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Desconecta do admin
  Future<void> _disconnect() async {
    // Limpa o estado da conexão
    await AppStateService.clearActiveConnection();
    
    setState(() {
      _isConnected = false;
      _activeConnectionId = null;
      _activeConnectionPin = null;
      _connectionDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Desconectado com sucesso'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Formata a data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
