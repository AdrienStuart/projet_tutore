// ============================================
// PRODUCTEUR SERVICE
// Fichier: lib/core/services/producteur_service.dart
// ============================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parcelle.dart';
import '../models/stock.dart';
import '../models/lot.dart';
import '../models/produit.dart';
import '../models/activite.dart';
import '../models/prevision.dart';
import 'offline_manager.dart';

class ProducteurService {
  final SupabaseClient _supabase;

  ProducteurService(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // PARCELLES
  // ============================================

  /// Récupérer toutes les parcelles du producteur connecté
  Future<List<Parcelle>> getMesParcelles() async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    final response = await _supabase
        .from('parcelles')
        .select()
        .eq('producteur_id', _currentUserId!)
        .order('nom', ascending: true);

    return (response as List).map((e) => Parcelle.fromJson(e)).toList();
  }

  /// Récupérer les activités d'une parcelle
  Future<List<Activite>> getActivitesParcelle(String parcelleId) async {
    final response = await _supabase
        .from('activites')
        .select()
        .eq('parcelle_id', parcelleId)
        .order('date_action', ascending: false);

    return (response as List).map((e) => Activite.fromJson(e)).toList();
  }

  /// Ajouter une activité sur une parcelle
  Future<Activite> ajouterActivite(Activite activite) async {
    // Mode offline
    if (!await OfflineManager.isOnline()) {
      await OfflineManager.enqueueAction('ajouter_activite', activite.toJson());
      return activite; // Retour optimiste
    }

    final response = await _supabase
        .from('activites')
        .insert(activite.toJson())
        .select()
        .single();

    return Activite.fromJson(response);
  }

  // ============================================
  // PRODUITS
  // ============================================

  /// Récupérer tous les produits disponibles
  Future<List<Produit>> getAllProduits() async {
    // Essayer cache d'abord
    final cached = OfflineManager.getCachedList('produits');
    if (cached.isNotEmpty) {
      return cached.map((e) => Produit.fromJson(e)).toList();
    }

    final response = await _supabase
        .from('produits')
        .select()
        .order('nom', ascending: true);

    // Mettre en cache
    await OfflineManager.cacheData('produits', {'items': response});

    return (response as List).map((e) => Produit.fromJson(e)).toList();
  }

  // ============================================
  // STOCKS
  // ============================================

  /// Récupérer tous les stocks du producteur avec leurs lots
  Future<List<Stock>> getMesStocks({bool avecLots = false}) async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    String query = avecLots
        ? 'id, producteur_id, produit_id, nom, qte_disponible, nbre_lots, seuil_alerte, dernier_mise_a_jour, produits(id, nom, categorie, duree_vie, prix_standard), lots(id, code_qr, date_recolte, qte_restante, statut)'
        : 'id, producteur_id, produit_id, nom, qte_disponible, nbre_lots, seuil_alerte, dernier_mise_a_jour, produits(id, nom, categorie, duree_vie, prix_standard)';

    final response = await _supabase
        .from('stocks')
        .select(query)
        .eq('producteur_id', _currentUserId!)
        .order('nom', ascending: true);

    return (response as List).map((e) => Stock.fromJson(e)).toList();
  }

  /// Créer un nouveau stock
  Future<Stock> creerStock({
    required String produitId,
    required String nom,
    double seuilAlerte = 50.0,
  }) async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    // Mode offline
    if (!await OfflineManager.isOnline()) {
      final stockData = {
        'producteur_id': _currentUserId,
        'produit_id': produitId,
        'nom': nom,
        'seuil_alerte': seuilAlerte,
      };
      await OfflineManager.enqueueAction('creer_stock', stockData);
      throw Exception('Stock enregistré hors ligne, sera synchronisé');
    }

    final response = await _supabase.from('stocks').insert({
      'producteur_id': _currentUserId,
      'produit_id': produitId,
      'nom': nom,
      'seuil_alerte': seuilAlerte,
    }).select('*, produits(*)').single();

    return Stock.fromJson(response);
  }

  /// Modifier un stock
  Future<void> modifierStock({
    required String stockId,
    String? nom,
    double? seuilAlerte,
  }) async {
    final updates = <String, dynamic>{};
    if (nom != null) updates['nom'] = nom;
    if (seuilAlerte != null) updates['seuil_alerte'] = seuilAlerte;

    if (updates.isEmpty) return;

    await _supabase.from('stocks').update(updates).eq('id', stockId);
  }

  // ============================================
  // LOTS
  // ============================================

  /// Déclarer une récolte (créer un lot)
  Future<Lot> declarerRecolte({
    required String parcelleId,
    required String produitId,
    required DateTime dateRecolte,
    required double quantite,
    String? stockId,
  }) async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    // Si pas de stock spécifié, créer/récupérer le stock "Vrac"
    String finalStockId = stockId ?? '';
    
    if (stockId == null) {
      // Chercher un stock "Vrac {Nom Produit}"
      final produit = await _supabase
          .from('produits')
          .select('nom')
          .eq('id', produitId)
          .single();
      
      final nomVrac = 'Vrac ${produit['nom']}';
      
      // Essayer de trouver ce stock
      final stocksExistants = await _supabase
          .from('stocks')
          .select('id')
          .eq('producteur_id', _currentUserId!)
          .eq('produit_id', produitId)
          .eq('nom', nomVrac)
          .maybeSingle();

      if (stocksExistants != null) {
        finalStockId = stocksExistants['id'];
      } else {
        // Créer le stock Vrac
        final nouveauStock = await _supabase.from('stocks').insert({
          'producteur_id': _currentUserId,
          'produit_id': produitId,
          'nom': nomVrac,
          'seuil_alerte': 50.0,
        }).select('id').single();
        
        finalStockId = nouveauStock['id'];
      }
    }

    final lotData = {
      'stock_id': finalStockId,
      'produit_id': produitId,
      'parcelle_id': parcelleId,
      'producteur_id': _currentUserId,
      'date_recolte': dateRecolte.toIso8601String().split('T')[0],
      'qte_initiale': quantite,
      'qte_restante': quantite,
    };

    // Mode offline
    if (!await OfflineManager.isOnline()) {
      await OfflineManager.enqueueAction('declarer_recolte', lotData);
      // Retourner un lot temporaire avec QR local
      return Lot(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        codeQr: 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
        stockId: finalStockId,
        produitId: produitId,
        parcelleId: parcelleId,
        producteurId: _currentUserId!,
        dateRecolte: dateRecolte,
        qteInitiale: quantite,
        qteRestante: quantite,
        statut: StatutLot.frais,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final response = await _supabase
        .from('lots')
        .insert(lotData)
        .select('*, produits(*), parcelles(*)')
        .single();

    return Lot.fromJson(response);
  }

  /// Récupérer tous les lots du producteur
  Future<List<Lot>> getMesLots({
    bool masquerVendus = true,
    StatutLot? filtreStatut,
    String? filtreProduit,
  }) async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    var query = _supabase
        .from('lots')
        .select('*, produits(*), parcelles(*)')
        .eq('producteur_id', _currentUserId!);

    if (masquerVendus) {
      query = query.gt('qte_restante', 0);
    }

    if (filtreStatut != null) {
      final statutStr = filtreStatut == StatutLot.frais ? 'Frais' 
                      : filtreStatut == StatutLot.critique ? 'Critique' 
                      : 'Perime';
      query = query.eq('statut', statutStr);
    }

    if (filtreProduit != null) {
      query = query.eq('produit_id', filtreProduit);
    }

    final response = await query.order('date_recolte', ascending: false);

    return (response as List).map((e) => Lot.fromJson(e)).toList();
  }

  /// Récupérer un lot par son code QR
  Future<Lot?> getLotParCodeQR(String codeQr) async {
    final response = await _supabase
        .from('lots')
        .select('*, produits(*), parcelles(*)')
        .eq('code_qr', codeQr)
        .maybeSingle();

    return response != null ? Lot.fromJson(response) : null;
  }

  // ============================================
  // PRÉVISIONS
  // ============================================

  /// Récupérer les prévisions actives pour les produits du producteur
  Future<List<Prevision>> getPrevisionsActives() async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    // Récupérer les produits que le producteur cultive
    final mesProduits = await _supabase
        .from('stocks')
        .select('produit_id')
        .eq('producteur_id', _currentUserId!);

    final produitIds = (mesProduits as List)
        .map((e) => e['produit_id'] as String)
        .toSet()
        .toList();

    if (produitIds.isEmpty) return [];

    final response = await _supabase
        .from('previsions_demande')
        .select('*, produits(*)')
        .inFilter('produit_id', produitIds)
        .eq('est_active', true)
        .gte('horizon_temporel', DateTime.now().toIso8601String().split('T')[0])
        .order('horizon_temporel', ascending: true)
        .limit(5);

    return (response as List).map((e) => Prevision.fromJson(e)).toList();
  }

  // ============================================
  // DASHBOARD STATS
  // ============================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    // Utiliser la vue v_dashboard_producteur
    final response = await _supabase
        .from('v_dashboard_producteur')
        .select()
        .eq('producteur_id', _currentUserId!)
        .maybeSingle();

    if (response == null) {
      return {
        'total_parcelles': 0,
        'total_stocks': 0,
        'total_lots': 0,
        'qte_disponible_totale': 0.0,
        'lots_critiques': 0,
        'lots_perimes': 0,
        'ca_total': 0.0,
        'taux_fraicheur': 100.0,
      };
    }

    return {
      'total_parcelles': await _countParcelles(),
      'total_stocks': response['total_stocks'],
      'total_lots': response['total_lots'],
      'qte_disponible_totale': response['qte_disponible_totale'],
      'lots_critiques': response['lots_critiques'],
      'lots_perimes': response['lots_perimes'],
      'ca_total': response['ca_total'],
      'taux_fraicheur': response['taux_fraicheur'] ?? 100.0,
    };
  }

  Future<int> _countParcelles() async {
    final response = await _supabase
        .from('parcelles')
        .select('id')
        .eq('producteur_id', _currentUserId!)
        .count();
    
    return response.count;
  }

  /// Récupérer les alertes critiques
  Future<List<Map<String, dynamic>>> getAlertesCritiques() async {
    if (_currentUserId == null) throw Exception('Non authentifié');

    final alertes = <Map<String, dynamic>>[];

    // Lots critiques
    final lotsCritiques = await _supabase
        .from('lots')
        .select('*, produits(nom)')
        .eq('producteur_id', _currentUserId!)
        .eq('statut', 'Critique')
        .gt('qte_restante', 0)
        .limit(5);

    for (var lot in lotsCritiques) {
      alertes.add({
        'type': 'lot_critique',
        'titre': 'Lot proche péremption',
        'message': '${lot['produits']['nom']} - ${lot['qte_restante']}kg',
        'urgence': 'Moyen',
        'data': lot,
      });
    }

    // Stocks bas
    final stocksBas = await _supabase
        .from('stocks')
        .select('*, produits(nom)')
        .eq('producteur_id', _currentUserId!)
        .lt('qte_disponible', _supabase.rpc('seuil_alerte'))
        .limit(5);

    for (var stock in stocksBas) {
      final qte = stock['qte_disponible'];
      final seuil = stock['seuil_alerte'];
      final critique = qte < seuil * 0.5;
      
      alertes.add({
        'type': 'stock_bas',
        'titre': 'Stock bas',
        'message': '${stock['produits']['nom']} - ${qte}kg (seuil: ${seuil}kg)',
        'urgence': critique ? 'Critique' : 'Moyen',
        'data': stock,
      });
    }

    return alertes;
  }
}