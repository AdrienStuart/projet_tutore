import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineManager {
  static late Box<Map> _cacheBox;
  static late Box<Map> _queueBox;

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
