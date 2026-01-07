// ============================================
// PRODUCTEUR HOME SCREEN (Dashboard)
// Fichier: lib/features/producteur/screens/producteur_home_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/stat_card.dart';
//import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../coeur/services/producteur_service.dart';
import '../../../coeur/services/supabase_service.dart';
import '../../../coeur/services/offline_manager.dart';
import '../../../coeur/models/prevision.dart';
import '../widgets/alerte_card.dart';
import '../widgets/prevision_card.dart';
//import '../widgets/parcelle_mini_card.dart';
import 'mes_stocks_screen.dart';
import 'declarer_recolte_screen.dart';
import 'parcelles_screen.dart';

class ProducteurHomeScreen extends StatefulWidget {
  const ProducteurHomeScreen({Key? key}) : super(key: key);

  @override
  State<ProducteurHomeScreen> createState() => _ProducteurHomeScreenState();
}

class _ProducteurHomeScreenState extends State<ProducteurHomeScreen> {
  late final ProducteurService _producteurService;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _alertes = [];
  List<Prevision> _previsions = [];
  int _actionsOffline = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _producteurService = ProducteurService(SupabaseService().client);
    _loadData();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    OfflineManager.connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncOfflineActions();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _producteurService.getDashboardStats();
      final alertes = await _producteurService.getAlertesCritiques();
      final previsions = await _producteurService.getPrevisionsActives();
      final actionsOffline = OfflineManager.getPendingActions().length;

      setState(() {
        _stats = stats;
        _alertes = alertes;
        _previsions = previsions;
        _actionsOffline = actionsOffline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncOfflineActions() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      // TODO: Implémenter synchronisation globale
      await Future.delayed(const Duration(seconds: 2));
      await _loadData();
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Accueil',
        showBackButton: false,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Chargement...',
        child: Column(
          children: [
            // Indicateur offline
            if (_actionsOffline > 0)
              OfflineIndicator(
                actionsEnAttente: _actionsOffline,
                onSync: _syncOfflineActions,
                isSyncing: _isSyncing,
              ),

            // Contenu principal
            Expanded(
              child: _error != null
                  ? ErrorState(message: _error!, onRetry: _loadData)
                  : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildContent() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Statistiques clés
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Section 2: Alertes critiques
          if (_alertes.isNotEmpty) ...[
            _buildAlertesSection(),
            const SizedBox(height: 24),
          ],

          // Section 3: Prévisions IA
          if (_previsions.isNotEmpty) ...[
            _buildPrevisionsSection(),
            const SizedBox(height: 24),
          ],

          // Section 4: Bouton Gérer mes Stocks
          _buildStocksButton(),

          const SizedBox(height: 80), // Espace pour bottom nav
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              title: 'Parcelles',
              value: '${_stats!['total_parcelles']}',
              icon: Icons.terrain,
              color: Colors.green,
              onTap: () => _navigateToParcelles(),
            ),
            StatCard(
              title: 'Lots actifs',
              value: '${_stats!['total_lots']}',
              icon: Icons.inventory_2,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Stock total',
              value: '${_stats!['qte_disponible_totale'].toInt()}kg',
              icon: Icons.scale,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Alertes',
              value: '${_stats!['lots_critiques']}',
              icon: Icons.warning,
              color: _stats!['lots_critiques'] > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alertes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Voir toutes les alertes
              },
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _alertes.take(3).length,
          itemBuilder: (context, index) {
            final alerte = _alertes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AlerteCard(
                type: alerte['type'],
                titre: alerte['titre'],
                message: alerte['message'],
                urgence: alerte['urgence'],
                onTap: () {
                  // TODO: Navigation vers détail
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrevisionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prévisions de demande',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _previsions.length,
            itemBuilder: (context, index) {
              final prevision = _previsions[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _previsions.length - 1 ? 12 : 0,
                ),
                child: PrevisionCard(prevision: prevision),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStocksButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MesStocksScreen(),
          ),
        );
      },
      icon: const Icon(Icons.inventory),
      label: const Text('Gérer mes Stocks'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            // Déjà sur Accueil
            break;
          case 1:
            _navigateToRecolte();
            break;
          case 2:
            _navigateToParcelles();
            break;
          case 3:
            _navigateToProfil();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Récolte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.terrain),
          label: 'Parcelles',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  void _navigateToRecolte() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeclarerRecolteScreen(),
      ),
    );
  }

  void _navigateToParcelles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParcellesScreen(),
      ),
    );
  }

  void _navigateToProfil() {
    // TODO: Implémenter écran profil
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Écran Profil à venir')),
    );
  }
}
