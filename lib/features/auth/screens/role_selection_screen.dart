
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/services/auth_service.dart';
import 'package:projet_tutore/coeur/services/supabase_service.dart';
//import 'package:projet_tutore/coeur/utils/constants.dart';
import 'package:projet_tutore/coeur/utils/snackbar_helper.dart';
import 'package:projet_tutore/coeur/utils/validators.dart';
import 'package:projet_tutore/shared/widgets/custom_app_bar.dart';
import 'package:projet_tutore/shared/widgets/custom_dropdown.dart';
import 'package:projet_tutore/shared/widgets/custom_text_field.dart';
import 'package:projet_tutore/shared/widgets/loading_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomFermeController = TextEditingController();
  final _typeActiviteController = TextEditingController(); // Acheteur

  String _selectedRole = 'Producteur'; // Default
  bool _isLoading = false;
  
  Map<String, dynamic>? _registrationData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve arguments passed from RegisterScreen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _registrationData = args;
    } else {
      // Fallback or error handling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.showError(context, 'Erreur de navigation. Retour à l\'inscription.');
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _nomFermeController.dispose();
    _typeActiviteController.dispose();
    super.dispose();
  }

  Future<void> _handleValidation() async {
    if (_registrationData == null) return;
    if (!_formKey.currentState!.validate()) return;
    
    // If Transporteur, navigate to Proof Submission with all data
    if (_selectedRole == 'Transporteur') {
         Navigator.of(context).pushNamed(
        '/proof_submission',
        arguments: {
          ..._registrationData!,
          'typeUtilisateur': 'Transporteur',
        },
      );
      return;
    }

    // Else finalize registration here
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService(SupabaseService().client);
      
      Map<String, dynamic> extraData = {};
      
      if (_selectedRole == 'Producteur') {
        extraData['nom_ferme'] = _nomFermeController.text;
        extraData['anciennete'] = 0; 
      } else if (_selectedRole == 'Acheteur') {
        extraData['type_activite'] = _typeActiviteController.text.isNotEmpty 
            ? _typeActiviteController.text 
            : 'Particulier';
      }

      await authService.signUp(
        email: _registrationData!['email'],
        password: _registrationData!['password'],
        nom: _registrationData!['nom'],
        telephone: _registrationData!['telephone'],
        adresse: _registrationData!['adresse'],
        typeUtilisateur: _selectedRole,
        extraData: extraData,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Inscription réussie !');
        // Redirection logic
         if (_selectedRole == 'Producteur') {
          Navigator.of(context).pushNamedAndRemoveUntil('/pending_approval', (route) => false);
        } else {
          // Acheteur or Admin
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
           SnackbarHelper.showInfo(context, 'Veuillez vous connecter.');
        }
      }

    } on AuthException catch (e) {
      SnackbarHelper.showError(context, e.message);
    } catch (e) {
      SnackbarHelper.showError(context, 'Erreur inattendue: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registrationData == null) {
        // While waiting for didChangeDependencies or if error
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Choisir son profil (2/2)'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text(
                'Quel type d\'utilisateur êtes-vous ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Role Cards
               _buildRoleCard('Producteur', Icons.agriculture, Colors.green),
               const SizedBox(height: 10),
               _buildRoleCard('Acheteur', Icons.shopping_cart, Colors.blue),
               const SizedBox(height: 10),
               _buildRoleCard('Transporteur', Icons.local_shipping, Colors.orange),
               const SizedBox(height: 10),
               _buildRoleCard('Admin', Icons.admin_panel_settings, Colors.grey),
               
               const SizedBox(height: 24),
               const Divider(),
               const SizedBox(height: 16),
               
               // Role Specific Form
               Form(
                 key: _formKey,
                 child: _buildSpecificFields(),
               ),
               
               const SizedBox(height: 32),
               
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _handleValidation,
                   style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                   child: Text(_selectedRole == 'Transporteur' ? 'Suivant (Preuves)' : 'Valider l\'inscription'),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 12),
            Text(
              role,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificFields() {
    if (_selectedRole == 'Producteur') {
        return Column(
          children: [
             CustomTextField(
                controller: _nomFermeController,
                label: 'Nom de la ferme',
                prefixIcon: Icons.landscape,
                validator: Validators.required,
             ),
          ],
        );
    } else if (_selectedRole == 'Acheteur') {
        return Column(
          children: [
             CustomDropdown<String>(
              value: 'Grossiste',
              items: const [
                DropdownMenuItem(value: 'Grossiste', child: Text('Grossiste')),
                DropdownMenuItem(value: 'Détaillant', child: Text('Détaillant')),
                DropdownMenuItem(value: 'Transformateur', child: Text('Transformateur')),
                DropdownMenuItem(value: 'Particulier', child: Text('Particulier')),
              ],
              onChanged: (val) {
                  if (val != null) _typeActiviteController.text = val;
              },
              label: 'Type d\'activité',
              prefixIcon: Icons.business,
            ),
          ],
        );
    }
    // Transporteur and Admin have no specific fields here (Transporteur handled in next screen)
    return const SizedBox.shrink();
  }
}
