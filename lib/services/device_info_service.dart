import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Battery _battery = Battery();
  static final NetworkInfo _networkInfo = NetworkInfo();

  /// Captura informações completas do dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      Map<String, dynamic> info = {};

      // Informações básicas do dispositivo
      info.addAll(await _getBasicDeviceInfo());
      
      // Informações da bateria
      info.addAll(await _getBatteryInfo());
      
      // Informações de conectividade
      info.addAll(await _getConnectivityInfo());
      
      // Informações de localização
      info.addAll(await _getLocationInfo());

      return info;
    } catch (e) {
      print('❌ Erro ao obter informações do dispositivo: $e');
      return {};
    }
  }

  /// Informações básicas do dispositivo
  static Future<Map<String, dynamic>> _getBasicDeviceInfo() async {
    Map<String, dynamic> info = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        info['deviceModel'] = androidInfo.model;
        info['deviceBrand'] = androidInfo.brand;
        info['androidVersion'] = androidInfo.version.release;
        info['sdkVersion'] = androidInfo.version.sdkInt;
        info['deviceId'] = androidInfo.id;
        info['manufacturer'] = androidInfo.manufacturer;
        info['product'] = androidInfo.product;
        info['hardware'] = androidInfo.hardware;
        info['fingerprint'] = androidInfo.fingerprint;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        info['deviceModel'] = iosInfo.model;
        info['deviceName'] = iosInfo.name;
        info['systemName'] = iosInfo.systemName;
        info['systemVersion'] = iosInfo.systemVersion;
        info['deviceId'] = iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('⚠️ Erro ao obter informações básicas: $e');
    }

    return info;
  }

  /// Informações da bateria
  static Future<Map<String, dynamic>> _getBatteryInfo() async {
    Map<String, dynamic> info = {};

    try {
      // Nível da bateria
      int batteryLevel = await _battery.batteryLevel;
      info['batteryLevel'] = batteryLevel;
      info['batteryPercentage'] = '$batteryLevel%';

      // Status da bateria
      BatteryState batteryState = await _battery.batteryState;
      info['batteryState'] = _getBatteryStateText(batteryState);
      info['isCharging'] = batteryState == BatteryState.charging;

      // Se está conectado à energia
      bool isConnected = await _battery.isInBatterySaveMode;
      info['batterySaveMode'] = isConnected;
    } catch (e) {
      print('⚠️ Erro ao obter informações da bateria: $e');
    }

    return info;
  }

  /// Informações de conectividade
  static Future<Map<String, dynamic>> _getConnectivityInfo() async {
    Map<String, dynamic> info = {};

    try {
      // Tipo de conectividade
      ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      info['connectionType'] = _getConnectionTypeText(connectivityResult);
      info['isConnected'] = connectivityResult != ConnectivityResult.none;

      // Informações específicas da rede
      if (connectivityResult == ConnectivityResult.wifi) {
        String? wifiName = await _networkInfo.getWifiName();
        String? wifiBSSID = await _networkInfo.getWifiBSSID();
        String? wifiIP = await _networkInfo.getWifiIP();
        
        info['wifiName'] = wifiName ?? 'Desconhecido';
        info['wifiBSSID'] = wifiBSSID ?? 'N/A';
        info['wifiIP'] = wifiIP ?? 'N/A';
        info['networkName'] = wifiName ?? 'WiFi';
      } else if (connectivityResult == ConnectivityResult.mobile) {
        String? mobileIP = await _networkInfo.getWifiIP(); // Pode retornar IP móvel
        info['mobileIP'] = mobileIP ?? 'N/A';
        info['networkName'] = 'Dados Móveis';
      }

      // Informações gerais da rede
      String? gateway = await _networkInfo.getWifiGatewayIP();
      info['gatewayIP'] = gateway ?? 'N/A';
    } catch (e) {
      print('⚠️ Erro ao obter informações de conectividade: $e');
    }

    return info;
  }

  /// Informações de localização
  static Future<Map<String, dynamic>> _getLocationInfo() async {
    Map<String, dynamic> info = {};

    try {
      // Verifica se o GPS está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      info['gpsEnabled'] = serviceEnabled;

      // Permissões de localização
      LocationPermission permission = await Geolocator.checkPermission();
      info['locationPermission'] = _getPermissionText(permission);

      // Última posição conhecida
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        info['lastKnownAccuracy'] = '${lastPosition.accuracy.toStringAsFixed(2)}m';
        info['lastKnownTimestamp'] = lastPosition.timestamp?.toIso8601String() ?? 'N/A';
      }
    } catch (e) {
      print('⚠️ Erro ao obter informações de localização: $e');
    }

    return info;
  }

  /// Converte status da bateria para texto
  static String _getBatteryStateText(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Carregando';
      case BatteryState.discharging:
        return 'Descarregando';
      case BatteryState.full:
        return 'Completa';
      case BatteryState.unknown:
        return 'Desconhecido';
      default:
        return 'N/A';
    }
  }

  /// Converte tipo de conectividade para texto
  static String _getConnectionTypeText(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Dados Móveis';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Outro';
      case ConnectivityResult.none:
        return 'Sem Conexão';
      default:
        return 'Desconhecido';
    }
  }

  /// Converte permissão para texto
  static String _getPermissionText(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Negada';
      case LocationPermission.deniedForever:
        return 'Negada Permanentemente';
      case LocationPermission.whileInUse:
        return 'Enquanto Usa';
      case LocationPermission.always:
        return 'Sempre';
      case LocationPermission.unableToDetermine:
        return 'Não Determinada';
      default:
        return 'Desconhecida';
    }
  }
}
