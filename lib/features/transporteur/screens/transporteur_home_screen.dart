// ============================================
// DASHBOARD TRANSPORTEUR
// ============================================
// Écran principal du module Transporteur
// - Stats du jour (livraisons, revenus)
// - Bouton "Commandes Disponibles"
// - Liste aperçu "Mes Livraisons En Cours"
// - Navigation vers toutes les sections
// ============================================

import 'package:flutter/material.dart';
import '../../../coeur/services/transporteur_service.dart';
import '../../../coeur/services/location_service.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../coeur/utils/formatters.dart';
import '../../../coeur/models/livraison.dart';
import './livraisons_disponibles_screen.dart';
import './mes_livraisons_screen.dart';
import './detail_livraison_screen.dart';
import '../widgets/livraison_card.dart';

class TransporteurHomeScreen extends StatefulWidget {
  const TransporteurHomeScreen({super.key});

  @override
  State<TransporteurHomeScreen> createState() => _TransporteurHomeScreenState();
}

class _TransporteurHomeScreenState extends State<TransporteurHomeScreen> {
  final TransporteurService _service = TransporteurService();
  
  // État
  bool _isLoading = true;
  Map<String, dynamic>? _statsDuJour;
  List<Livraison> _livraisonsEnCours = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Demander permission GPS (nécessaire pour livraisons)
    _requestLocationPermission();
  }

  // ============================================
  // CHARGEMENT DONNÉES
  // ============================================
  
  Future<void> _loadData() async {
    // If mounted check is good practice but keeping user code as close as possible
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger en parallèle
      final results = await Future.wait([
        _service.getStatsDuJour(),
        _service.getMesLivraisons(filtre: StatutLivraison.enCours),
      ]);

      if (!mounted) return;
      setState(() {
        _statsDuJour = results[0] as Map<String, dynamic>;
        _livraisonsEnCours = (results[1] as List<Livraison>).take(3).toList();
        _isLoading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final hasPermission = await LocationService.checkPermissions();
      if (!hasPermission) {
        // Afficher dialog pour expliquer pourquoi c'est nécessaire
        if (mounted) {
          _showLocationPermissionDialog();
        }
      }
    } catch (e) {
      print('Erreur permission GPS: $e');
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission GPS Requise'),
        content: const Text(
          'L\'accès à votre position est nécessaire pour:\n'
          '• Afficher votre position sur la carte\n'
          '• Calculer les distances de livraison\n'
          '• Optimiser vos itinéraires',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de Bord',
        actions: [
          // Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const LoadingOverlay(
                isLoading: true,
                message: 'Chargement...',
                child: SizedBox.shrink(),
              )
            : _buildContent(),
      ),
      
      // FAB: Voir commandes disponibles
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToDisponibles(),
        icon: const Icon(Icons.local_shipping),
        label: const Text('Commandes Dispo'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur offline
          OfflineIndicator(
            actionsEnAttente: 0,
            onSync: () {},
          ),
          const SizedBox(height: 16),
          
          // Stats du jour
          _buildStatsSection(),
          const SizedBox(height: 24),
          
          // Mes livraisons en cours (aperçu)
          _buildLivraisonsSection(),
          const SizedBox(height: 80),  // Espace pour FAB
        ],
      ),
    );
  }

  // ============================================
  // SECTION STATS
  // ============================================
  
  Widget _buildStatsSection() {
    if (_statsDuJour == null) return const SizedBox.shrink();

    final stats = _statsDuJour!;
    final enCours = stats['livraisons_en_cours'] as int? ?? 0;
    final terminees = stats['livraisons_terminees_jour'] as int? ?? 0;
    final revenus = stats['revenus_jour'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aujourd\'hui',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Grille 2x2 de stats
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            // En cours
            StatCard(
              title: 'En Cours',
              value: enCours.toString(),
              icon: Icons.local_shipping,
              color: Colors.blue,
              onTap: () => _navigateToMesLivraisons(
                initialTab: StatutLivraison.enCours,
              ),
            ),
            
            // Terminées aujourd'hui
            StatCard(
              title: 'Terminées',
              value: terminees.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () => _navigateToMesLivraisons(
                initialTab: StatutLivraison.terminee,
              ),
            ),
            
            // Revenus du jour
            StatCard(
              title: 'Revenus',
              value: Formatters.formatMontant(revenus),
              icon: Icons.attach_money,
              color: Colors.orange,
            ),
            
            // Total livraisons
            StatCard(
              title: 'Total',
              value: (enCours + terminees).toString(),
              icon: Icons.list_alt,
              color: Colors.purple,
              onTap: () => _navigateToMesLivraisons(),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================
  // SECTION LIVRAISONS EN COURS
  // ============================================
  
  Widget _buildLivraisonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec bouton "Voir tout"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Livraisons En Cours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_livraisonsEnCours.isNotEmpty)
              TextButton(
                onPressed: () => _navigateToMesLivraisons(
                  initialTab: StatutLivraison.enCours,
                ),
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Liste des livraisons
        if (_livraisonsEnCours.isEmpty)
          _buildEmptyState()
        else
          ..._livraisonsEnCours.map((livraison) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LivraisonCard(
                livraison: livraison,
                onTap: () => _navigateToDetail(livraison),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune livraison en cours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consultez les commandes disponibles pour commencer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToDisponibles,
            icon: const Icon(Icons.search),
            label: const Text('Voir Commandes'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // NAVIGATION
  // ============================================
  
  void _navigateToDisponibles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LivraisonsDisponiblesScreen(),
      ),
    ).then((_) => _loadData());  // Refresh au retour
  }

  void _navigateToMesLivraisons({StatutLivraison? initialTab}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesLivraisonsScreen(initialTab: initialTab),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToDetail(Livraison livraison) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLivraisonScreen(livraisonId: livraison.id),
      ),
    ).then((_) => _loadData());
  }
}
