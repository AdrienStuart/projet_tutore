import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/livraison.dart';

class OfflineManager {
  static late Box<Map> _cacheBox;
  static late Box<Map> _queueBox;

  // NOUVEAUX POUR TRANSPORTEUR
  static const String _boxLivraisons = 'livraisons_cache';
  static const String _boxStats = 'transporteur_stats';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Box pour cache lecture
    _cacheBox = await Hive.openBox<Map>('data_cache');

    // Box pour queue d'actions offline
    _queueBox = await Hive.openBox<Map>('offline_queue');
  }

  // Cache - Lecture
  static Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _cacheBox.put(key, data);
  }

  static Map<String, dynamic>? getCachedData(String key) {
    final cached = _cacheBox.get(key);
    return cached != null ? Map<String, dynamic>.from(cached) : null;
  }

  static List<Map<String, dynamic>> getCachedList(String key) {
    final cached = _cacheBox.get(key);
    if (cached == null) return [];
    return List<Map<String, dynamic>>.from(
        (cached['items'] as List).map((e) => Map<String, dynamic>.from(e)));
  }

  // Queue - Écriture offline
  static Future<void> enqueueAction(
      String action, Map<String, dynamic> data) async {
    final actionId = DateTime.now().millisecondsSinceEpoch.toString();
    await _queueBox.put(actionId, {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'attempts': 0,
      'status': 'pending',
    });
  }

  static List<Map<String, dynamic>> getPendingActions() {
    return _queueBox.values
        .where((a) => a['status'] == 'pending')
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> markActionSynced(String actionId) async {
    final action = _queueBox.get(actionId);
    if (action != null) {
      action['status'] = 'synced';
      action['synced_at'] = DateTime.now().toIso8601String();
      await _queueBox.put(actionId, action);
    }
  }

  static Future<void> clearSyncedActions() async {
    final syncedKeys = _queueBox.keys
        .where((key) => _queueBox.get(key)?['status'] == 'synced')
        .toList();
    for (var key in syncedKeys) {
      await _queueBox.delete(key);
    }
  }

  // Connectivité
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}

extension TransporteurCache on OfflineManager {
  
  // ============================================
  // 1. CACHE LIVRAISONS
  // ============================================
  
  /// Sauvegarde mes livraisons en cache local
  /// APPELÉ APRÈS: getMesLivraisons() en online
  Future<void> saveLivraisons(List<Livraison> livraisons) async {
    try {
      final box = await Hive.openBox(OfflineManager._boxLivraisons);
      
      // Convertir en Map pour Hive
      final data = livraisons.map((l) => l.toJson()).toList();
      
      await box.put('mes_livraisons', data);
      await box.put('last_sync', DateTime.now().toIso8601String());
      
    } catch (e) {
      print('Erreur saveLivraisons: $e');
    }
  }

  /// Charge les livraisons depuis le cache
  /// APPELÉ EN: Mode offline
  Future<List<Livraison>> getLivraisonsFromCache({
    StatutLivraison? filtre,
  }) async {
    try {
      final box = await Hive.openBox(OfflineManager._boxLivraisons);
      final data = box.get('mes_livraisons') as List?;
      
      if (data == null) return [];
      
      var livraisons = data
          .cast<Map<String, dynamic>>()
          .map((json) => Livraison.fromJson(json))
          .toList();
      
      // Appliquer filtre si nécessaire
      if (filtre != null) {
        livraisons = livraisons.where((l) => l.statut == filtre).toList();
      }
      
      return livraisons;
      
    } catch (e) {
      print('Erreur getLivraisonsFromCache: $e');
      return [];
    }
  }

  /// Obtient la date de dernière synchro
  Future<DateTime?> getLastSyncDate() async {
    try {
      final box = await Hive.openBox(OfflineManager._boxLivraisons);
      final dateStr = box.get('last_sync') as String?;
      return dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // 2. CACHE STATISTIQUES
  // ============================================
  
  /// Sauvegarde les statistiques
  Future<void> saveStats(Map<String, dynamic> stats) async {
    try {
      final box = await Hive.openBox(OfflineManager._boxStats);
      await box.put('stats', stats);
      await box.put('stats_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur saveStats: $e');
    }
  }

  /// Charge les statistiques depuis cache
  Future<Map<String, dynamic>> getStatsFromCache() async {
    try {
      final box = await Hive.openBox(OfflineManager._boxStats);
      final stats = box.get('stats') as Map<String, dynamic>?;
      
      return stats ?? {
        'total_livraisons': 0,
        'livraisons_terminees': 0,
        'livraisons_en_cours': 0,
        'taux_ponctualite': 0.0,
        'revenus_totaux': 0.0,
      };
      
    } catch (e) {
      return {
        'total_livraisons': 0,
        'livraisons_terminees': 0,
        'livraisons_en_cours': 0,
        'taux_ponctualite': 0.0,
        'revenus_totaux': 0.0,
      };
    }
  }

  // ============================================
  // 3. NETTOYAGE CACHE (Maintenance)
  // ============================================
  
  /// Nettoie les livraisons terminées anciennes (> 30 jours)
  /// APPELÉ: Périodiquement ou au démarrage de l'app
  Future<void> cleanOldLivraisons() async {
    try {
      final box = await Hive.openBox(OfflineManager._boxLivraisons);
      final data = box.get('mes_livraisons') as List?;
      
      if (data == null) return;
      
      final livraisons = data
          .cast<Map<String, dynamic>>()
          .map((json) => Livraison.fromJson(json))
          .toList();
      
      // Garde seulement livraisons < 30 jours ou non terminées
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final filtered = livraisons.where((l) {
        if (l.dateArriveeReelle == null) return true;  // En cours: garder
        return l.dateArriveeReelle!.isAfter(cutoffDate);  // Terminée récente: garder
      }).toList();
      
      // Sauvegarder la liste filtrée
      await box.put('mes_livraisons', filtered.map((l) => l.toJson()).toList());
      
    } catch (e) {
      print('Erreur cleanOldLivraisons: $e');
    }
  }

  // ============================================
  // 4. HELPER: Taille du cache
  // ============================================
  
  /// Retourne la taille du cache en MB (pour debug)
  Future<double> getCacheSizeMB() async {
    try {
      final boxLivraisons = await Hive.openBox(OfflineManager._boxLivraisons);
      final boxStats = await Hive.openBox(OfflineManager._boxStats);
      
      // Calcul approximatif (à affiner)
      final livraisonsSize = boxLivraisons.length * 2;  // ~2 KB par livraison
      final statsSize = 1;  // ~1 KB
      
      return (livraisonsSize + statsSize) / 1024;  // En MB
      
    } catch (e) {
      return 0.0;
    }
  }
}
