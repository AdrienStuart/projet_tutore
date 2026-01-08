import 'package:flutter/material.dart';
import '../../../coeur/services/transporteur_service.dart';
import '../../../coeur/models/livraison.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/commande_card.dart';

class LivraisonsDisponiblesScreen extends StatefulWidget {
  const LivraisonsDisponiblesScreen({super.key});

  @override
  State<LivraisonsDisponiblesScreen> createState() => _LivraisonsDisponiblesScreenState();
}

class _LivraisonsDisponiblesScreenState extends State<LivraisonsDisponiblesScreen> {
  final TransporteurService _service = TransporteurService();
  List<CommandeDisponible> _commandes = [];
  bool _isLoading = true;
  String? _error;
  
  // Pour éviter double-click sur accepter
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final commandes = await _service.getCommandesDisponibles();
      if (mounted) {
        setState(() {
          _commandes = commandes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAccept(CommandeDisponible commande) async {
    // Vérifier si peut prendre livraison
    final peutPrendre = await _service.peutPrendreNouvelleLivraison();
    if (!peutPrendre) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez atteint votre limite de livraisons simultanées.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _processingId = commande.id);

    try {
      await _service.prendreLivraison(commandeId: commande.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison acceptée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh liste (la commande devrait disparaître)
        _loadCommandes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes Disponibles'),
      ),
      body: Column(
        children: [
          OfflineIndicator(
            actionsEnAttente: 0,
            onSync: () {},
          ),
          Expanded(
            child: _isLoading && _commandes.isEmpty
                ? const LoadingOverlay(
                    isLoading: true,
                    message: 'Recherche de commandes...',
                    child: SizedBox.shrink(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCommandes,
                    child: _buildList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.error_outline, color: Colors.red, size: 48),
             const SizedBox(height: 16),
             Text(_error!),
             ElevatedButton(onPressed: _loadCommandes, child: const Text('Réessayer'))
          ],
        ),
      );
    }

    if (_commandes.isEmpty) {
      return const EmptyState(
        title: 'Aucune commande',
        message: 'Aucune commande disponible pour le moment.',
        icon: Icons.access_time,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commandes.length,
      itemBuilder: (context, index) {
        final commande = _commandes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CommandeCard(
            commande: commande,
            isLoading: _processingId == commande.id,
            onAccept: () => _handleAccept(commande),
          ),
        );
      },
    );
  }
}
