import 'package:flutter/material.dart';
import '../../../coeur/services/transporteur_service.dart';
import '../../../coeur/models/livraison.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/livraison_card.dart';
import './detail_livraison_screen.dart';

class MesLivraisonsScreen extends StatefulWidget {
  final StatutLivraison? initialTab;
  
  const MesLivraisonsScreen({
    super.key, 
    this.initialTab,
  });

  @override
  State<MesLivraisonsScreen> createState() => _MesLivraisonsScreenState();
}

class _MesLivraisonsScreenState extends State<MesLivraisonsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransporteurService _service = TransporteurService();
  
  bool _isLoading = true;
  List<Livraison> _allLivraisons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Sélectionner l'onglet initial
    if (widget.initialTab != null) {
      // Mapping index enum -> index tab (Attention si l'ordre change)
      // Enum: aVenir(0), enCours(1), terminee(2)
      // Tabs: En Cours(0), A Venir(1), Terminées(2) -> On préfère En Cours en premier
      int tabIndex = 0;
      if (widget.initialTab == StatutLivraison.enCours) tabIndex = 0;
      if (widget.initialTab == StatutLivraison.aVenir) tabIndex = 1;
      if (widget.initialTab == StatutLivraison.terminee) tabIndex = 2;
      
      _tabController.animateTo(tabIndex);
    }

    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() => _isLoading = true);
    try {
      final livraisons = await _service.getMesLivraisons();
      if (mounted) {
        setState(() {
          _allLivraisons = livraisons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); // Gérer erreur ?
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En Cours'),
            Tab(text: 'À Venir'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineIndicator(
            actionsEnAttente: 0,
            onSync: () {},
          ),
          Expanded(
            child: _isLoading 
              ? const LoadingOverlay(
                  isLoading: true,
                  message: 'Chargement...',
                  child: SizedBox.shrink(),
                ) 
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLivraisonsList(StatutLivraison.enCours),
                    _buildLivraisonsList(StatutLivraison.aVenir),
                    _buildLivraisonsList(StatutLivraison.terminee),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivraisonsList(StatutLivraison status) {
    final filtered = _allLivraisons.where((l) => l.statut == status).toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        title: 'Aucune livraison',
        message: 'Aucune livraison dans cette catégorie',
        icon: Icons.local_shipping_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLivraisons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final livraison = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LivraisonCard(
              livraison: livraison,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailLivraisonScreen(livraisonId: livraison.id),
                  ),
                );
                _loadLivraisons(); // Reload au retour
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
