import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'utils/app_constants.dart';
import 'utils/firebase_config.dart';
import 'services/app_state_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await FirebaseConfig.initialize();
  
  // Cria as coleções necessárias
  await FirebaseConfig.createCollectionsIfNotExist();
  
  // Inicializa o serviço de estado da aplicação
  await AppStateService.initialize();
  
  runApp(const LoveConfApp());
}

class LoveConfApp extends StatelessWidget {
  const LoveConfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
