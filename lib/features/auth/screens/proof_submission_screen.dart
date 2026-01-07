
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/services/auth_service.dart';
import 'package:projet_tutore/coeur/services/supabase_service.dart';
//import 'package:projet_tutore/coeur/utils/constants.dart';
import 'package:projet_tutore/coeur/utils/snackbar_helper.dart';
import 'package:projet_tutore/coeur/utils/validators.dart';
import 'package:projet_tutore/shared/widgets/custom_app_bar.dart';
import 'package:projet_tutore/shared/widgets/custom_text_field.dart';
import 'package:projet_tutore/shared/widgets/loading_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProofSubmissionScreen extends StatefulWidget {
  const ProofSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<ProofSubmissionScreen> createState() => _ProofSubmissionScreenState();
}

class _ProofSubmissionScreenState extends State<ProofSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capaciteController = TextEditingController();
  
  Map<String, dynamic>? _registrationData;
  bool _isLoading = false;
  bool _photoUploaded = false; // Simulation

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _registrationData = args;
    }
  }

  @override
  void dispose() {
    _capaciteController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    // TODO: Implement Logic using image_picker
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _photoUploaded = true;
    });
    if (mounted) SnackbarHelper.showSuccess(context, 'Preuve chargée avec succès !');
  }

  Future<void> _finalizeRegistration() async {
    if (_registrationData == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_photoUploaded) {
      SnackbarHelper.showError(context, 'Veuillez charger une preuve (photo obligatoire).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService(SupabaseService().client);
      
      Map<String, dynamic> extraData = {
        'capacite_vehicule': int.tryParse(_capaciteController.text) ?? 500,
        // 'proof_url': '...' // Would be added here
      };

      await authService.signUp(
        email: _registrationData!['email'],
        password: _registrationData!['password'],
        nom: _registrationData!['nom'],
        telephone: _registrationData!['telephone'],
        adresse: _registrationData!['adresse'],
        typeUtilisateur: 'Transporteur',
        extraData: extraData,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Inscription réussie ! En attente de validation.');
        Navigator.of(context).pushNamedAndRemoveUntil('/pending_approval', (route) => false);
      }
    } on AuthException catch (e) {
      SnackbarHelper.showError(context, e.message);
    } catch (e) {
      SnackbarHelper.showError(context, 'Erreur inattendue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Preuves Transporteur'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Validation du statut Transporteur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Pour finaliser votre inscription, des preuves sont nécessaires.'),
                const SizedBox(height: 24),
                
                CustomTextField(
                  controller: _capaciteController,
                  label: 'Capacité estimée du véhicule (kg)',
                  prefixIcon: Icons.speed,
                  keyboardType: TextInputType.number,
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 24),
                
                const Text('Photo du permis ou du véhicule (Obligatoire)'),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _photoUploaded 
                      ? const Center(child: Icon(Icons.check_circle, size: 50, color: Colors.green))
                      : Center(
                          child: IconButton(
                            icon: const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            onPressed: _handleUpload,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _finalizeRegistration,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Envoyer et Finaliser'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
