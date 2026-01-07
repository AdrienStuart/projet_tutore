
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);
  
  // Inscription
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nom,
    required String telephone,
    required String adresse,
    required String typeUtilisateur, // Producteur, Transporteur, Acheteur
    Map<String, dynamic>? extraData,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
        'type_utilisateur': typeUtilisateur,
        ...?extraData,
      },
    );
    
    if (response.user != null) {
      // Créer l'entrée dans la table utilisateurs
      await _supabase.from('utilisateurs').insert({
        'id': response.user!.id,
        'type_utilisateur': typeUtilisateur,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'adresse': adresse,
        'mot_de_passe_hashe': 'managed_by_supabase_auth',
      });
      
      // Créer l'entrée dans la table spécifique (producteurs, etc.)
      if (typeUtilisateur == 'Producteur') {
        await _supabase.from('producteurs').insert({
          'id': response.user!.id,
          'anciennete': extraData?['anciennete'] ?? 0,
          'nom_ferme': extraData?['nom_ferme'],
        });
      } else if (typeUtilisateur == 'Transporteur') {
        await _supabase.from('transporteurs').insert({
          'id': response.user!.id,
          'capacite_vehicule': extraData?['capacite_vehicule'] ?? 500,
          'disponibilite': true,
        });
      } else if (typeUtilisateur == 'Acheteur') {
        await _supabase.from('acheteurs').insert({
          'id': response.user!.id,
          'type_activite': extraData?['type_activite'] ?? 'Grossiste',
        });
      }
    }
    
    return response;
  }
  
  // Connexion
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Écouter les changements d'état auth
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Obtenir profil complet
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    final response = await _supabase
        .from('utilisateurs')
        .select('*, producteurs(*), transporteurs(*), acheteurs(*)')
        .eq('id', userId)
        .single();
    
    return response;
  }
}