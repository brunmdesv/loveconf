import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../models/location_record.dart';


class LocationDetailsScreen extends StatefulWidget {
  final LocationRecord location;

  const LocationDetailsScreen({
    super.key,
    required this.location,
  });

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  String? _fullAddress;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadFullAddress();
  }

  Future<void> _loadFullAddress() async {
    try {
      setState(() {
        _isLoadingAddress = true;
      });

      // Tenta obter o endereço completo usando as coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        
        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        setState(() {
          _fullAddress = address;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _fullAddress = 'Endereço não disponível';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullAddress = 'Erro ao carregar endereço';
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Localização'),
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
          child: Column(
            children: [
                             // Mapa real do Google Maps
               Expanded(
                 flex: 2,
                 child: Container(
                   margin: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(
                       color: AppTheme.accentColor.withValues(alpha: 0.3),
                       width: 2,
                     ),
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(16),
                     child: GoogleMap(
                       initialCameraPosition: CameraPosition(
                         target: LatLng(
                           widget.location.latitude,
                           widget.location.longitude,
                         ),
                         zoom: 15.0,
                       ),
                       mapType: MapType.hybrid, // Modo satelite
                       markers: {
                         Marker(
                           markerId: MarkerId('location_${widget.location.id}'),
                           position: LatLng(
                             widget.location.latitude,
                             widget.location.longitude,
                           ),
                           infoWindow: InfoWindow(
                             title: 'Localização Capturada',
                             snippet: widget.location.coordinatesText,
                           ),
                           icon: BitmapDescriptor.defaultMarkerWithHue(
                             BitmapDescriptor.hueBlue,
                           ),
                         ),
                       },
                       myLocationEnabled: false,
                       myLocationButtonEnabled: false,
                       zoomControlsEnabled: true,
                       mapToolbarEnabled: false,
                     ),
                   ),
                 ),
               ),

              // Informações detalhadas
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Informações da Localização',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Lista de informações
                          Expanded(
                            child: ListView(
                              children: [
                                _buildInfoItem(
                                  icon: Icons.gps_fixed,
                                  title: 'Coordenadas GPS',
                                  value: widget.location.coordinatesText,
                                  isMonospace: true,
                                ),
                                
                                _buildInfoItem(
                                  icon: Icons.place,
                                  title: 'Endereço',
                                  value: _isLoadingAddress 
                                      ? 'Carregando...' 
                                      : (_fullAddress ?? 'Não disponível'),
                                ),
                                
                                _buildInfoItem(
                                  icon: Icons.access_time,
                                  title: 'Data e Hora',
                                  value: widget.location.fullTimestamp,
                                ),
                                
                                _buildInfoItem(
                                  icon: Icons.schedule,
                                  title: 'Tempo Relativo',
                                  value: widget.location.formattedTimestamp,
                                ),
                                
                                if (widget.location.connectionPin != null)
                                  _buildInfoItem(
                                    icon: Icons.link,
                                    title: 'PIN da Conexão',
                                    value: widget.location.connectionPin!,
                                  ),
                                
                                _buildInfoItem(
                                  icon: Icons.person,
                                  title: 'ID do Cliente',
                                  value: widget.location.clientId,
                                  isMonospace: true,
                                ),
                                
                                _buildInfoItem(
                                  icon: Icons.admin_panel_settings,
                                  title: 'ID do Admin',
                                  value: widget.location.adminId,
                                  isMonospace: true,
                                ),
                                
                                _buildInfoItem(
                                  icon: Icons.location_on,
                                  title: 'Status',
                                  value: widget.location.isActive ? 'Ativa' : 'Inativa',
                                  valueColor: widget.location.isActive ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool isMonospace = false,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontFamily: isMonospace ? 'monospace' : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
