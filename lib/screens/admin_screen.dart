import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../models/connection.dart';
import '../services/connection_service.dart';
import '../services/app_state_service.dart';
import '../widgets/connection_card.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/gradient_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _initializeAdminId();
  }

  Future<void> _initializeAdminId() async {
    final adminId = await AppStateService.getOrCreateAdminId();
    setState(() {
      _adminId = adminId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_adminId == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.adminTitle),
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
                          Icons.admin_panel_settings,
                          size: 50,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.adminPanelTitle,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.adminSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão Criar Conexão
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GradientButton(
                    text: 'Criar Conexão',
                    onPressed: _isLoading ? () {} : () => _createConnection(),
                    icon: Icons.add_link,
                    width: double.infinity,
                  ),
                ),

                                // Lista de Conexões
                Expanded(
                  flex: 2,
                  child: StreamBuilder<List<Connection>>(
                    stream: ConnectionService.getConnectionsByAdmin(_adminId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('❌ Erro no StreamBuilder: ${snapshot.error}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar conexões',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentColor,
                          ),
                        );
                      }

                      final connections = snapshot.data ?? [];
                      print('📱 Conexões carregadas: ${connections.length}');

                      if (connections.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link_off,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma conexão criada',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clique em "Criar Conexão" para começar',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: connections.length,
                        itemBuilder: (context, index) {
                          final connection = connections[index];
                          print('🔗 Renderizando conexão: ${connection.pin} - ${connection.statusText}');
                          return ConnectionCard(
                            connection: connection,
                            onCancel: () => _cancelConnection(connection.id!),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cria uma nova conexão
  Future<void> _createConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final connection = await ConnectionService.createConnection(_adminId!);
      
      if (mounted) {
        // Mostra o diálogo com o PIN
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PinDialog(
            pin: connection.pin,
            onCopy: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppConstants.pinCopied} ${connection.pin}'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.connectionError}: $e'),
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

  // Cancela uma conexão
  Future<void> _cancelConnection(String connectionId) async {
    try {
      final success = await ConnectionService.cancelConnection(connectionId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                          content: Text(AppConstants.connectionCancelled),
            backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                          content: Text(AppConstants.cancelError),
            backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.cancelError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
