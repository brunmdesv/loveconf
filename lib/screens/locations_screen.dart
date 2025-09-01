import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/location_record.dart';
import '../services/location_service.dart';
import '../services/app_state_service.dart';
import '../services/export_service.dart';
import '../widgets/gradient_button.dart';
import 'location_details_screen.dart';

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
  List<LocationRecord> _filteredLocations = [];
  String? _clientId;
  String? _currentAdminId;
  
  // Filtros
  String _selectedFilter = 'todas'; // todas, hoje, semana, mes

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
        _filteredLocations = locations;
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
          _updateFilteredLocations();
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [


                // Botão Capturar Localização
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: _isLoading ? 'Capturando...' : 'Capturar Localização',
                    onPressed: _isLoading || !_hasLocationPermission ? () {} : () => _captureLocation(),
                    icon: _isLoading ? Icons.hourglass_empty : Icons.my_location,
                  ),
                ),

                const SizedBox(height: 12),

                // Filtros de data
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtrar por período:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip('todas', 'Todas'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('hoje', 'Hoje'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('semana', 'Esta Semana'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('mes', 'Este Mês'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Botão de Exportar
                if (_filteredLocations.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: '📤 Exportar Histórico',
                      onPressed: () => _showExportOptions(),
                      icon: Icons.file_download,
                      isOutlined: true,
                    ),
                  ),

                const SizedBox(height: 16),

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
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final location = _filteredLocations[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildLocationCard(LocationRecord location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToLocationDetails(location),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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

                const SizedBox(height: 12),

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



                // Indicador de toque
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toque para ver detalhes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navega para a tela de detalhes da localização
  void _navigateToLocationDetails(LocationRecord location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailsScreen(location: location),
      ),
    );
  }

  // Constrói um chip de filtro
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () => _applyFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentColor 
              : AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentColor 
                : AppTheme.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? AppTheme.textPrimary 
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Aplica o filtro selecionado
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredLocations = _filterLocationsByPeriod(filter);
    });
  }

  // Filtra localizações por período
  List<LocationRecord> _filterLocationsByPeriod(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (filter) {
      case 'hoje':
        return _locations.where((location) {
          final locationDate = DateTime(
            location.timestamp.year,
            location.timestamp.month,
            location.timestamp.day,
          );
          return locationDate.isAtSameMomentAs(today);
        }).toList();
        
      case 'semana':
        final weekAgo = today.subtract(const Duration(days: 7));
        return _locations.where((location) {
          return location.timestamp.isAfter(weekAgo);
        }).toList();
        
      case 'mes':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _locations.where((location) {
          return location.timestamp.isAfter(monthAgo);
        }).toList();
        
      default: // 'todas'
        return _locations;
    }
  }

  // Atualiza a lista filtrada quando as localizações mudam
  void _updateFilteredLocations() {
    _filteredLocations = _filterLocationsByPeriod(_selectedFilter);
  }

  // Mostra opções de exportação
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Histórico',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Estatísticas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', '${_filteredLocations.length}'),
                  _buildStatItem('Hoje', '${ExportService.generateStats(_filteredLocations)['today']}'),
                  _buildStatItem('Esta Semana', '${ExportService.generateStats(_filteredLocations)['thisWeek']}'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Opções de exportação
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'CSV',
                    Icons.table_chart,
                    () => _exportData('csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'JSON',
                    Icons.code,
                    () => _exportData('json'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'TXT',
                    Icons.text_snippet,
                    () => _exportData('txt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Constrói um item de estatística
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // Constrói um botão de exportação
  Widget _buildExportButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Exporta dados no formato selecionado
  Future<void> _exportData(String format) async {
    try {
      Navigator.pop(context); // Fecha o modal
      
      // Mostra indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Exportando dados...'),
          backgroundColor: AppTheme.accentColor,
        ),
      );

      // Exporta baseado no formato
      switch (format) {
        case 'csv':
          await ExportService.exportAndShareCSV(_filteredLocations);
          break;
        case 'json':
          await ExportService.exportAndShareJSON(_filteredLocations);
          break;
        case 'txt':
          await ExportService.exportAndShareText(_filteredLocations);
          break;
      }

      // Sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dados exportados em $format!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
