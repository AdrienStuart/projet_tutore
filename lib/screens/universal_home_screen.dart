
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/services/auth_service.dart';
import 'package:projet_tutore/coeur/services/supabase_service.dart';
import 'package:projet_tutore/shared/widgets/custom_app_bar.dart';

class UniversalHomeScreen extends StatelessWidget {
  const UniversalHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = SupabaseService().client;
    final user = client.auth.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Accueil',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService(client).getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final profile = snapshot.data;
          final role = profile?['type_utilisateur'] ?? 'Inconnu';
          final name = profile?['nom'] ?? user?.email ?? 'Utilisateur';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text('Bienvenue, $name !', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(
                  label: Text(role.toUpperCase()),
                  backgroundColor: Colors.green[100],
                  labelStyle: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 32),
                const Text('Ceci est l\'écran d\'accueil commun.'),
                const SizedBox(height: 16),
                // Conditional buttons based on role could go here
                 if (role == 'Producteur') 
                   const Text('(Fonctionnalités Producteur activées)'),
                 if (role == 'Transporteur') 
                   const Text('(Fonctionnalités Transporteur activées)'),
              ],
            ),
          );
        },
      ),
    );
  }
}
