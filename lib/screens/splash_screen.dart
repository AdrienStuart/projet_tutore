
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/services/supabase_service.dart';
import 'package:projet_tutore/coeur/services/auth_service.dart';
import 'package:projet_tutore/coeur/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final supabase = SupabaseService();
    
    if (supabase.isAuthenticated) {
      // Récupérer le type d'utilisateur
      final profile = await AuthService(supabase.client).getProfile();
      final typeUtilisateur = profile?['type_utilisateur'];
      
      // Rediriger selon le rôle
      switch (typeUtilisateur) {
        case 'Producteur':
          Navigator.of(context).pushReplacementNamed('/producteur');
          break;
        case 'Acheteur':
          Navigator.of(context).pushReplacementNamed('/acheteur');
          break;
        case 'Transporteur':
          Navigator.of(context).pushReplacementNamed('/transporteur');
          break;
        case 'Admin':
          Navigator.of(context).pushReplacementNamed('/admin');
          break;
        default:
          Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.agriculture,
                size: 100,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AgroNet',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Traçabilité Intelligente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
