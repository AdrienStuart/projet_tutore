// ============================================
// MAIN.DART - Configuration complète avec module Producteur
// Fichier: lib/main.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';

// coeur Services
import 'coeur/services/supabase_service.dart';
import 'coeur/services/offline_manager.dart';
//import 'coeur/services/auth_service.dart';
import 'coeur/utils/constants.dart';

// Screens
import 'screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/producteur/screens/producteur_home_screen.dart';
// import 'features/acheteur/screens/acheteur_home_screen.dart';
// import 'features/transporteur/screens/transporteur_home_screen.dart';
// import 'features/admin/screens/admin_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser Hive (cache offline)
  await OfflineManager.initialize();

  // 2. Initialiser Supabase
  await SupabaseService().initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 3. Synchroniser actions offline au démarrage
  try {
    await syncOfflineActions();
  } catch (e) {
    debugPrint('Synchronisation initiale échouée: $e');
  }

  runApp(const MyApp());
}

// Fonction de synchronisation globale
Future<void> syncOfflineActions() async {
  if (!await OfflineManager.isOnline()) return;

  final supabase = SupabaseService().client;
  final pendingActions = OfflineManager.getPendingActions();

  for (var action in pendingActions) {
    try {
      await executeOfflineAction(supabase, action);
      await OfflineManager.markActionSynced(action['id']);
    } catch (e) {
      debugPrint('Erreur sync action ${action['action']}: $e');
    }
  }

  // Nettoyer les actions synchronisées
  await OfflineManager.clearSyncedActions();
}

Future<void> executeOfflineAction(
    dynamic supabase, Map<String, dynamic> action) async {
  switch (action['action']) {
    case 'declarer_recolte':
      await supabase.from('lots').insert(action['data']);
      break;
    case 'creer_stock':
      await supabase.from('stocks').insert(action['data']);
      break;
    case 'ajouter_activite':
      await supabase.from('activites').insert(action['data']);
      break;
    case 'creer_commande':
      await supabase.rpc('creer_commande', params: action['data']);
      break;
    // Ajouter d'autres actions...
    default:
      debugPrint('Action inconnue: ${action['action']}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNet',
      debugShowCheckedModeBanner: false,

      // Thème
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',

        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Localizations
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),

      // Routes
      initialRoute: '/login',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/producteur': (context) => const ProducteurHomeScreen(),
        // '/acheteur': (context) => const AcheteurHomeScreen(),
        // '/transporteur': (context) => const TransporteurHomeScreen(),
        // '/admin': (context) => const AdminHomeScreen(),
      },
    );
  }
}
