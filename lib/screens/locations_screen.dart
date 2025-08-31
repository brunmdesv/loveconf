import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/location_record.dart';
import '../services/location_service.dart';
import '../services/app_state_service.dart';
import '../widgets/gradient_button.dart';

class LocationsScreen extends StatefulWidget {
  final String? connectionPin;
  final String? adminId;

  const LocationsScreen({
    super.key,
    this.connectionPin,
    this.adminId,
  });

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _isLoading = false;
  bool _hasLocationPermission = false;
  List<LocationRecord> _locations = [];
  String? _clientId;
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    print('🚀 Inicializando tela de localizações...');
    
    // Obtém o ID do cliente
    _clientId = await AppStateService.getOrCreateClientId();
    
    // Obtém o ID do admin da conexão ativa ou do parâmetro
    if (widget.adminId != null) {
      _currentAdminId = widget.adminId;
    } else if (widget.connectionPin != null) {
      // Busca o admin da conexão
      final connection = await _getConnectionByPin(widget.connectionPin!);
      _currentAdminId = connection?['adminId'];
    }

    // Verifica permissões de localização
    await _checkLocationPermissions();
    
    // Carrega as localizações
    await _loadLocations();
    
    print('✅ Tela de localizações inicializada');
  }

  Future<Map<String, dynamic>?> _getConnectionByPin(String pin) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('connections')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar conexão por PIN: $e');
      return null;
    }
  }

  Future<void> _checkLocationPermissions() async {
    print('🔐 Verificando permissões de localização...');
    
    final hasPermission = await LocationService.hasLocationPermission();
    setState(() {
      _hasLocationPermission = hasPermission;
    });
    
    print('🔐 Permissões de localização: $_hasLocationPermission');
  }

  Future<void> _loadLocations() async {
    print('📱 Carregando localizações...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<LocationRecord> locations = [];
      
      if (widget.connectionPin != null) {
        // Busca localizações por PIN de conexão
        locations = await LocationService.getLocationsByPin(widget.connectionPin!);
      } else if (_clientId != null) {
        // Busca todas as localizações do cliente
        locations = await LocationService.getClientLocations(_clientId!);
      }
      
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
      
      print('✅ ${locations.length} localizações carregadas');
    } catch (e) {
      print('❌ Erro ao carregar localizações: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _captureLocation() async {
    print('📍 Capturando localização...');
    
    if (_clientId == null || _currentAdminId == null) {
      print('❌ IDs não disponíveis para captura');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: IDs não disponíveis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Captura a localização atual
      LocationRecord? locationRecord = await LocationService.captureCurrentLocation(
        clientId: _clientId!,
        adminId: _currentAdminId!,
        connectionPin: widget.connectionPin,
      );

      if (locationRecord != null) {
        // Adiciona a nova localização à lista
        setState(() {
          _locations.insert(0, locationRecord);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Localização capturada: ${locationRecord.coordinatesText}'),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        print('✅ Localização capturada e salva com sucesso');
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao capturar localização'),
            backgroundColor: Colors.red,
          ),
        );

        print('❌ Falha ao capturar localização');
      }
    } catch (e) {
      print('❌ Erro ao capturar localização: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestLocationPermissions() async {
    print('🔐 Solicitando permissões de localização...');
    
    final granted = await LocationService.requestLocationPermission();
    
    if (granted) {
      setState(() {
        _hasLocationPermission = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Permissões de localização concedidas!'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('✅ Permissões de localização concedidas');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Permissões de localização negadas'),
          backgroundColor: Colors.orange,
        ),
      );
      
      print('⚠️ Permissões de localização negadas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizações'),
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
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
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
                          Icons.location_on,
                          size: 40,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Histórico de Localizações',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Visualize e capture localizações em tempo real',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Botões de ação
                Row(
                  children: [
                                         // Botão de Permissões
                     Expanded(
                       child: GradientButton(
                         text: _hasLocationPermission ? 'Permissões Ativas' : 'Ativar Localização',
                         onPressed: _hasLocationPermission ? () {} : () => _requestLocationPermissions(),
                         icon: _hasLocationPermission ? Icons.check_circle : Icons.location_on,
                         isOutlined: _hasLocationPermission,
                       ),
                     ),
                     const SizedBox(width: 16),
                     // Botão Capturar Localização
                     Expanded(
                       child: GradientButton(
                         text: _isLoading ? 'Capturando...' : 'Capturar Localização',
                         onPressed: _isLoading || !_hasLocationPermission ? () {} : () => _captureLocation(),
                         icon: _isLoading ? Icons.hourglass_empty : Icons.my_location,
                       ),
                     ),
                  ],
                ),

                const SizedBox(height: 24),

                // Lista de localizações
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentColor,
                          ),
                        )
                      : _locations.isEmpty
                          ? _buildEmptyState()
                          : _buildLocationsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma localização encontrada',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture sua primeira localização para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildLocationCard(LocationRecord location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do card
              Row(
                children: [
                  Icon(
                    location.isRecent ? Icons.location_on : Icons.location_on_outlined,
                    color: location.isRecent ? AppTheme.accentColor : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Localização',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          location.formattedTimestamp,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (location.isRecent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'RECENTE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Coordenadas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.coordinatesText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Endereço (se disponível)
              if (location.address != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.place,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Timestamp completo
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.fullTimestamp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              // PIN da conexão (se disponível)
              if (location.connectionPin != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PIN: ${location.connectionPin}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
