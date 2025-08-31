import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../theme/app_theme.dart';

class ConnectionCard extends StatelessWidget {
  final Connection connection;
  final VoidCallback onCancel;

  const ConnectionCard({
    super.key,
    required this.connection,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com status e PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.statusText,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PIN: ${connection.pin}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor().withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    connection.statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Data de criação
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Criada em: ${connection.formattedCreatedAt}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            // Data de conexão (se conectado)
            if (connection.status == ConnectionStatus.connected && connection.connectedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Conectada em: ${connection.formattedConnectedAt}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ],
            
            // Data de cancelamento (se cancelado)
            if (connection.status == ConnectionStatus.cancelled && connection.cancelledAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.cancel,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cancelada em: ${connection.cancelledAt!.day.toString().padLeft(2, '0')}/${connection.cancelledAt!.month.toString().padLeft(2, '0')}/${connection.cancelledAt!.year} ${connection.cancelledAt!.hour.toString().padLeft(2, '0')}:${connection.cancelledAt!.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            
            // Botão de cancelar (apenas para conexões aguardando)
            if (connection.status == ConnectionStatus.waiting) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cancelar Conexão',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (connection.status) {
      case ConnectionStatus.waiting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return AppTheme.accentColor;
      case ConnectionStatus.cancelled:
        return Colors.red;
    }
  }
}
