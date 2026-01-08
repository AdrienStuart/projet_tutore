// ============================================
// SERVICE TRANSPORTEUR
// ============================================
// Gère toute la logique métier du module Transporteur
// - Charger commandes disponibles
// - Prendre une livraison (premier arrivé)
// - Mettre à jour position GPS
// - Marquer livraison comme terminée
// - Statistiques dashboard
// ============================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/livraison.dart';
import './offline_manager.dart';


class TransporteurService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OfflineManager _offlineManager = OfflineManager(); // Instance for extension methods

  // ============================================
  // 1. RÉCUPÉRER COMMANDES DISPONIBLES
  // ============================================
  
  /// Charge les commandes status='Validee' (non prises)
  /// Utilise la vue v_livraisons_disponibles (déjà triée par ancienneté)
  /// 
  /// CACHE: Pas de cache pour cette liste (temps réel important)
  Future<List<CommandeDisponible>> getCommandesDisponibles() async {
    try {
      // Requête vers la vue (déjà optimisée avec index)
      final response = await _supabase
          .from('v_livraisons_disponibles')
          .select()
          .order('priorite', ascending: true)  // Ordre: plus ancienne en premier
          .limit(50);  // Limite pour performance
      
      return (response as List)
          .map((json) => CommandeDisponible.fromSupabase(json))
          .toList();
          
    } catch (e) {
      // En offline: retourne liste vide (pas critique)
      print('Erreur getCommandesDisponibles: $e');
      return [];
    }
  }

  // ============================================
  // 2. PRENDRE UNE LIVRAISON (Premier Arrivé)
  // ============================================
  
  /// Appelle la fonction PostgreSQL prendre_livraison()
  /// Cette fonction gère le locking et le "premier arrivé"
  /// 
  /// OFFLINE: Action mise en queue si hors connexion
  Future<String?> prendreLivraison({
    required String commandeId,
    DateTime? dateDepart,      // Par défaut: NOW() + 30 minutes
    DateTime? dateArriveePrevue, // Par défaut: NOW() + 2 heures
  }) async {
    try {
      final transporteurId = _supabase.auth.currentUser!.id;
      
      // Paramètres avec valeurs par défaut
      final params = {
        'p_transporteur_id': transporteurId,
        'p_commande_id': commandeId,
        'p_date_depart': dateDepart?.toIso8601String(),
        'p_date_arrivee_prevue': dateArriveePrevue?.toIso8601String(),
      };
      
      // Appel de la fonction PostgreSQL
      final response = await _supabase.rpc('prendre_livraison', params: params);
      
      // Retourne l'ID de la livraison créée
      return response as String?;
      
    } on PostgrestException catch (e) {
      // Erreurs métier (déjà prise, max atteint, etc.)
      throw Exception(e.message);
      
    } catch (e) {
      // Offline: Mettre en queue
      if (!await OfflineManager.isOnline()) {
        await OfflineManager.enqueueAction('prendre_livraison', { // Static call
            'commande_id': commandeId,
            'date_depart': dateDepart?.toIso8601String(),
            'date_arrivee_prevue': dateArriveePrevue?.toIso8601String(),
        }); // Adjusted to use enqueueAction properly if signature matches
        // Wait, OfflineManager.enqueueAction signature is (String action, Map data).
        // The original code passed a Map with type/data/timestamp.
        // Let's check OfflineManager.enqueueAction signature in file.
        // It is: static Future<void> enqueueAction(String action, Map<String, dynamic> data)
        // Original code in snippet:
        /*
        await _offlineManager.queueAction({
          'type': 'prendre_livraison',
          'data': { ... }
        });
        */
        // The snippet assumes _offlineManager has queueAction (instance method? or typo?)
        // The EXISTING OfflineManager (Step 93) has `static Future<void> enqueueAction`.
        // So I should change `_offlineManager.queueAction(...)` to `OfflineManager.enqueueAction(...)`
        // AND match the arguments.
        // Existing `enqueueAction` takes (action, data).
        // The snippet passed a single map with 'type' (which is action) and 'data'.
        // So I must adapt the code.
        
        throw Exception('Action mise en queue (hors connexion)');
      }
      
      rethrow;
    }
  }

  // ============================================
  // ADAPTED METHODS FOR OFFLINE MANAGER STATIC CALLS
  // ============================================
  // I will adapt the code below to use OfflineManager.enqueueAction correctly.

  // ============================================
  // 3. MES LIVRAISONS (Filtres multiples)
  // ============================================
  
  /// Charge mes livraisons selon le filtre
  /// Utilise la vue v_mes_livraisons (avec RLS automatique)
  /// 
  /// CACHE: Sauvegarde locale pour mode offline
  Future<List<Livraison>> getMesLivraisons({
    StatutLivraison? filtre,  // null = toutes
  }) async {
    try {
      final transporteurId = _supabase.auth.currentUser!.id;
      
      var query = _supabase
          .from('v_mes_livraisons')
          .select()
          .eq('transporteur_id', transporteurId);
      
      // Appliquer filtre si nécessaire
      if (filtre == StatutLivraison.enCours) {
        query = query
            .filter('date_arrivee_reelle', 'is', null)
            .lte('date_depart', DateTime.now().toIso8601String());
      } else if (filtre == StatutLivraison.aVenir) {
        query = query
            .filter('date_arrivee_reelle', 'is', null)
            .gt('date_depart', DateTime.now().toIso8601String());
      } else if (filtre == StatutLivraison.terminee) {
        query = query.not('date_arrivee_reelle', 'is', null);
      }
      
      final response = await query.order('date_arrivee_prevue', ascending: true);
      
      final livraisons = (response as List)
          .map((json) => Livraison.fromSupabase(json))
          .toList();
      
      // CACHE: Sauvegarde en local providing instance method via extension
      await _offlineManager.saveLivraisons(livraisons);
      
      return livraisons;
      
    } catch (e) {
      // OFFLINE: Charge depuis le cache
      print('Erreur getMesLivraisons, charge cache: $e');
      return await _offlineManager.getLivraisonsFromCache(filtre: filtre);
    }
  }

  // ============================================
  // 4. DÉTAIL LIVRAISON (Avec route)
  // ============================================
  
  /// Charge une livraison spécifique avec son itinéraire
  Future<Livraison?> getDetailLivraison(String livraisonId) async {
    try {
      final response = await _supabase
          .from('v_mes_livraisons')
          .select()
          .eq('livraison_id', livraisonId)
          .single();
      
      return Livraison.fromSupabase(response);
      
    } catch (e) {
      // Offline: Cherche dans cache
      final cached = await _offlineManager.getLivraisonsFromCache();
      return cached.firstWhere(
        (l) => l.id == livraisonId,
        orElse: () => throw Exception('Livraison introuvable'),
      );
    }
  }

  // ============================================
  // 5. METTRE À JOUR POSITION GPS
  // ============================================
  
  /// Met à jour ma position GPS actuelle pour une livraison
  /// APPELÉ: Périodiquement pendant la livraison
  /// 
  /// OFFLINE: Batch en queue, envoyé plus tard
  Future<void> updatePositionGPS({
    required String livraisonId,
    required LatLng position,
  }) async {
    try {
      // Update table livraisons
      await _supabase
          .from('livraisons')
          .update({
            'position_actuelle': {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            },
          })
          .eq('id', livraisonId);
      
      // Update aussi table transporteurs (position globale)
      final transporteurId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('transporteurs')
          .update({
            'localisation_actuelle': {
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            },
          })
          .eq('id', transporteurId);
          
    } catch (e) {
      // Offline: Queue l'action
      if (!await OfflineManager.isOnline()) {
        await OfflineManager.enqueueAction('update_position', {
          'livraison_id': livraisonId,
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
    }
  }

  // ============================================
  // 6. DÉMARRER LIVRAISON
  // ============================================
  
  /// Change le statut à "en cours" (optionnel si date_depart déjà passée)
  /// APPELÉ: Quand le transporteur clique "Démarrer"
  Future<void> demarrerLivraison(String livraisonId) async {
    try {
      await _supabase
          .from('livraisons')
          .update({'date_depart': DateTime.now().toIso8601String()})
          .eq('id', livraisonId);
          
    } catch (e) {
      // Offline: Queue
      if (!await OfflineManager.isOnline()) {
        await OfflineManager.enqueueAction('demarrer_livraison', {
          'livraison_id': livraisonId,
        });
      }
    }
  }

  // ============================================
  // 7. MARQUER LIVRAISON TERMINÉE
  // ============================================
  
  /// CRITIQUE: Marque la livraison comme livrée
  /// Déclenche automatiquement (via trigger):
  /// - Déblocage des fonds (transaction)
  /// - Notification acheteur
  /// - Mise à jour livraisons_actives du transporteur
  /// 
  /// OFFLINE: Mise en queue prioritaire
  Future<void> marquerLivree(String livraisonId) async {
    try {
      await _supabase
          .from('livraisons')
          .update({'date_arrivee_reelle': DateTime.now().toIso8601String()})
          .eq('id', livraisonId);
      
      // Rafraîchir le cache local
      await getMesLivraisons();
      
    } catch (e) {
      // Offline: Queue PRIORITAIRE
      if (!await OfflineManager.isOnline()) {
         // Note: enqueueAction in current OfflineManager doesn't support 'priority' param.
         // Pass it in data for now if needed.
        await OfflineManager.enqueueAction('marquer_livree', {
          'livraison_id': livraisonId,
          'priority': 'high',
        });
        throw Exception('Action mise en queue (hors connexion)');
      }
      
      rethrow;
    }
  }

  // ============================================
  // 8. STATISTIQUES DASHBOARD
  // ============================================
  
  /// Charge les stats pour le dashboard
  /// Utilise la vue v_stats_transporteur (agrégations pré-calculées)
  Future<Map<String, dynamic>> getStatistiques() async {
    try {
      final transporteurId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('v_stats_transporteur')
          .select()
          .eq('transporteur_id', transporteurId)
          .single();
      
      // Cache les stats
      await _offlineManager.saveStats(response);
      
      return response;
      
    } catch (e) {
      // Offline: Charge cache (stats peuvent être obsolètes)
      print('Erreur getStatistiques, charge cache: $e');
      return await _offlineManager.getStatsFromCache();
    }
  }

  // ============================================
  // 9. STATS DU JOUR (Dashboard)
  // ============================================
  
  /// Stats rapides pour le dashboard (sans vue)
  Future<Map<String, dynamic>> getStatsDuJour() async {
    try {
      final transporteurId = _supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      // Livraisons du jour
      final livraisons = await _supabase
          .from('livraisons')
          .select('id, date_arrivee_reelle, commande_id!inner(montant_total)')
          .eq('transporteur_id', transporteurId)
          .gte('date_depart', startOfDay.toIso8601String());
      
      final total = livraisons.length;
      final terminees = livraisons.where((l) => l['date_arrivee_reelle'] != null).length;
      final enCours = total - terminees;
      
      // Revenus du jour (approximatif: 10% du montant commande)
      double revenusJour = 0;
      for (final l in livraisons) {
        if (l['date_arrivee_reelle'] != null) {
          final montant = (l['commande_id']['montant_total'] as num).toDouble();
          revenusJour += montant * 0.10;  // 10% transporteur
        }
      }
      
      return {
        'livraisons_en_cours': enCours,
        'livraisons_terminees_jour': terminees,
        'revenus_jour': revenusJour,
        'total_livraisons_jour': total,
      };
      
    } catch (e) {
      return {
        'livraisons_en_cours': 0,
        'livraisons_terminees_jour': 0,
        'revenus_jour': 0.0,
        'total_livraisons_jour': 0,
      };
    }
  }

  // ============================================
  // 10. OPTIMISATION SIMPLE (Distance)
  // ============================================
  
  /// Trie mes livraisons en cours par distance
  /// UTILISÉ POUR: Suggérer l'ordre optimal
  /// 
  /// ALGORITHME: Plus proche d'abord (greedy)
  /// Pour algo avancé (TSP): implémenter plus tard
  Future<List<Livraison>> optimiserItineraire(
    LatLng maPosition,
    List<Livraison> livraisons,
  ) async {
    if (livraisons.isEmpty) return [];
    if (livraisons.length == 1) return livraisons;
    
    // Calcule distance pour chaque livraison
    final List<MapEntry<Livraison, double>> withDistances = [];
    
    for (final liv in livraisons) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        maPosition,
        liv.destination,
      );
      withDistances.add(MapEntry(liv, distance));
    }
    
    // Trie par distance croissante
    withDistances.sort((a, b) => a.value.compareTo(b.value));
    
    return withDistances.map((e) => e.key).toList();
  }

  // ============================================
  // 11. HELPER: Vérifier disponibilité
  // ============================================
  
  /// Vérifie si je peux prendre une nouvelle livraison
  /// Check: livraisons_actives < max_livraisons_simultanees
  Future<bool> peutPrendreNouvelleLivraison() async {
    try {
      final transporteurId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('transporteurs')
          .select('livraisons_actives, max_livraisons_simultanees')
          .eq('id', transporteurId)
          .single();
      
      final actives = response['livraisons_actives'] as int;
      final max = response['max_livraisons_simultanees'] as int;
      
      return actives < max;
      
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // 12. STREAM TEMPS RÉEL (Optionnel)
  // ============================================
  
  /// Stream des nouvelles commandes disponibles
  /// UTILISE: Supabase Realtime (si activé)
  /// 
  /// SETUP REQUIS dans Supabase:
  /// 1. Activer Realtime sur table 'commandes'
  /// 2. Filter: status_cmd = 'Validee'
  Stream<List<CommandeDisponible>> streamCommandesDisponibles() {
    return _supabase
        .from('commandes')
        .stream(primaryKey: ['id'])
        .eq('status_cmd', 'Validee')
        .map((data) {
          // Transformer les données (simplifié)
          return data.map((json) {
            // Note: Stream ne passe pas par la vue, donc structure différente
            // À adapter selon vos besoins
            return CommandeDisponible(
              id: json['id'] as String,
              dateCmd: DateTime.parse(json['date_cmd'] as String),
              montantTotal: (json['montant_total'] as num).toDouble(),
              adresseLivraison: json['adresse_livraison'] as String,
              coordonneesLivraison: const LatLng(0, 0),  // Simplification
              acheteurNom: '',
              acheteurTelephone: '',
              produits: [],
              poidsTotalKg: 0,
              minutesDepuisValidation: 0,
              priorite: 0,
            );
          }).toList();
        });
  }
}
