
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/services/supabase_service.dart';
import 'package:projet_tutore/coeur/services/auth_service.dart';
import 'package:projet_tutore/coeur/utils/constants.dart';
import 'package:projet_tutore/coeur/utils/snackbar_helper.dart';
import 'package:projet_tutore/shared/widgets/custom_app_bar.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService().signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _uploadProof(BuildContext context) async {
    // TODO: Implement actual file upload
    SnackbarHelper.showInfo(context, 'Fonctionnalité d\'upload à venir. Simulation...');
    
    await Future.delayed(const Duration(seconds: 1));
    SnackbarHelper.showSuccess(context, 'Preuve envoyée à l\'admin !');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService(SupabaseService().client).getProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final type = profile?['type_utilisateur'] ?? 'Utilisateur';

        return Scaffold(
          appBar: CustomAppBar(
            title: 'En Attente de Validation',
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Compte $type en attente',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre inscription a bien été prise en compte et est en cours d\'examen par un administrateur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                if (type == 'Transporteur') ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Documents Requis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pour valider votre compte, veuillez fournir une photo de votre permis ou de votre véhicule.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _uploadProof(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Envoyer une preuve (Photo/PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondaryColor,
                    ),
                  ),
                ],
                const Spacer(),
                const Text(
                  'Vous serez notifié dès que votre compte sera activé.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
