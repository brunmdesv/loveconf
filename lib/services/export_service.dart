import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/location_record.dart';

class ExportService {
  /// Exporta localizações em formato CSV
  static Future<String> exportToCSV(List<LocationRecord> locations) async {
    if (locations.isEmpty) {
      throw Exception('Nenhuma localização para exportar');
    }

    final csvData = StringBuffer();
    
    // Cabeçalho
    csvData.writeln('Data/Hora,Latitude,Longitude,Endereço,PIN Conexão,ID Cliente,ID Admin,Status');
    
    // Dados
    for (final location in locations) {
      csvData.writeln([
        location.fullTimestamp,
        location.latitude,
        location.longitude,
        location.address ?? 'N/A',
        location.connectionPin ?? 'N/A',
        location.clientId,
        location.adminId,
        location.isActive ? 'Ativa' : 'Inativa',
      ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
    }

    return csvData.toString();
  }

  /// Exporta localizações em formato JSON
  static Future<String> exportToJSON(List<LocationRecord> locations) async {
    if (locations.isEmpty) {
      throw Exception('Nenhuma localização para exportar');
    }

    final jsonData = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalLocations': locations.length,
      'locations': locations.map((location) => location.toMap()).toList(),
    };

    return JsonEncoder.withIndent('  ').convert(jsonData);
  }

  /// Exporta localizações em formato de texto simples
  static Future<String> exportToText(List<LocationRecord> locations) async {
    if (locations.isEmpty) {
      throw Exception('Nenhuma localização para exportar');
    }

    final textData = StringBuffer();
    
    textData.writeln('RELATÓRIO DE LOCALIZAÇÕES');
    textData.writeln('==========================');
    textData.writeln('Data de exportação: ${DateTime.now().toString()}');
    textData.writeln('Total de localizações: ${locations.length}');
    textData.writeln('');
    
    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      textData.writeln('${i + 1}. LOCALIZAÇÃO');
      textData.writeln('   Data/Hora: ${location.fullTimestamp}');
      textData.writeln('   Coordenadas: ${location.coordinatesText}');
      textData.writeln('   Endereço: ${location.address ?? 'Não disponível'}');
      textData.writeln('   PIN Conexão: ${location.connectionPin ?? 'N/A'}');
      textData.writeln('   ID Cliente: ${location.clientId}');
      textData.writeln('   ID Admin: ${location.adminId}');
      textData.writeln('   Status: ${location.isActive ? 'Ativa' : 'Inativa'}');
      textData.writeln('');
    }

    return textData.toString();
  }

  /// Salva dados em um arquivo temporário
  static Future<File> _saveToTempFile(String content, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  /// Compartilha o arquivo exportado
  static Future<void> shareFile(File file, String filename) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Histórico de Localizações - $filename',
      text: 'Histórico de localizações exportado do app LoveConf',
    );
  }

  /// Exporta e compartilha em CSV
  static Future<void> exportAndShareCSV(List<LocationRecord> locations) async {
    try {
      final csvContent = await exportToCSV(locations);
      final file = await _saveToTempFile(csvContent, 'localizacoes.csv');
      await shareFile(file, 'localizacoes.csv');
    } catch (e) {
      throw Exception('Erro ao exportar CSV: $e');
    }
  }

  /// Exporta e compartilha em JSON
  static Future<void> exportAndShareJSON(List<LocationRecord> locations) async {
    try {
      final jsonContent = await exportToJSON(locations);
      final file = await _saveToTempFile(jsonContent, 'localizacoes.json');
      await shareFile(file, 'localizacoes.json');
    } catch (e) {
      throw Exception('Erro ao exportar JSON: $e');
    }
  }

  /// Exporta e compartilha em texto
  static Future<void> exportAndShareText(List<LocationRecord> locations) async {
    try {
      final textContent = await exportToText(locations);
      final file = await _saveToTempFile(textContent, 'localizacoes.txt');
      await shareFile(file, 'localizacoes.txt');
    } catch (e) {
      throw Exception('Erro ao exportar texto: $e');
    }
  }

  /// Gera estatísticas das localizações
  static Map<String, dynamic> generateStats(List<LocationRecord> locations) {
    if (locations.isEmpty) {
      return {
        'total': 0,
        'today': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'averageDistance': 0.0,
      };
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    double totalDistance = 0.0;
    int distanceCount = 0;

    for (final location in locations) {
      // Conta por período
      if (location.timestamp.isAfter(today)) {
        todayCount++;
      }
      if (location.timestamp.isAfter(weekAgo)) {
        weekCount++;
      }
      if (location.timestamp.isAfter(monthAgo)) {
        monthCount++;
      }

      // Calcula distância média (se houver mais de uma localização)
      if (locations.length > 1) {
        for (final other in locations) {
          if (location.id != other.id) {
            totalDistance += location.distanceTo(other);
            distanceCount++;
          }
        }
      }
    }

    return {
      'total': locations.length,
      'today': todayCount,
      'thisWeek': weekCount,
      'thisMonth': monthCount,
      'averageDistance': distanceCount > 0 ? totalDistance / distanceCount : 0.0,
    };
  }
}
