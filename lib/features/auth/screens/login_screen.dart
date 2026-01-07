import 'package:flutter/material.dart';
import '../../../coeur/services/supabase_service.dart';
import '../../../coeur/services/auth_service.dart';
import '../../../coeur/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'producteur@test.com');
  final _passwordController = TextEditingController(text: 'Test1234!');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService(SupabaseService().client);
      
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Récupérer le profil pour redirection
      final profile = await authService.getProfile();
      final typeUtilisateur = profile?['type_utilisateur'];

      if (!mounted) return;

      // Rediriger selon le rôle
      switch (typeUtilisateur) {
        case 'Producteur':
          Navigator.of(context).pushReplacementNamed('/producteur');
          break;
        case 'Acheteur':
        case 'Transporteur':
        case 'Admin':
          SnackbarHelper.showInfo(context, 'Module $typeUtilisateur à venir');
          break;
        default:
          SnackbarHelper.showError(context, 'Type utilisateur inconnu');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Connexion',
        showBackButton: false,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Connexion...',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'AgroNet',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Traçabilité Intelligente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email requis';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mot de passe
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mot de passe requis';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton connexion
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Infos de test
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '📝 Compte de test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Email: producteur@test.com',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Mot de passe: Test1234!',
                          style: TextStyle(fontSize: 12),
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
    );
  }
}