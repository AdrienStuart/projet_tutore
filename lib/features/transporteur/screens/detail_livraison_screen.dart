import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../coeur/models/livraison.dart';
import '../../../coeur/services/transporteur_service.dart';
import '../../../coeur/services/maps_service.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/loading_overlay.dart';

import '../widgets/map_widget.dart';

class DetailLivraisonScreen extends StatefulWidget {
  final String livraisonId;

  const DetailLivraisonScreen({
    super.key,
    required this.livraisonId,
  });

  @override
  State<DetailLivraisonScreen> createState() => _DetailLivraisonScreenState();
}

class _DetailLivraisonScreenState extends State<DetailLivraisonScreen> {
  final TransporteurService _transporteurService = TransporteurService();
  final MapsService _mapsService = MapsService();
  
  bool _isLoading = true;
  Livraison? _livraison;
  String? _error;
  
  // Map Data
  List<LatLng> _route = [];
  double _distanceKm = 0;
  
  // Action Loading
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final livraison = await _transporteurService.getDetailLivraison(widget.livraisonId);
      
      if (livraison != null) {
        // Calcul itinéraire si positions dispo
        if (livraison.positionActuelle != null) {
          _route = await _mapsService.getRoute(
            livraison.positionActuelle!, 
            livraison.destination
          );
          _distanceKm = await _mapsService.calculateDistanceKm(
             livraison.positionActuelle!, 
             livraison.destination
          );
        } else {
           // Simuler position départ (si pas encore prise en charge) -> destination
           // TODO: Utiliser position actuelle GPS réelle
        }
      }

      if (mounted) {
        setState(() {
          _livraison = livraison;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isActionLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action effectuée avec succès'), backgroundColor: Colors.green),
        );
        _loadDetails(); // Rafraîchir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingOverlay(
          isLoading: true,
          message: 'Chargement...',
          child: SizedBox.shrink(),
        ),
      );
    }
    if (_error != null || _livraison == null) return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(child: Text(_error ?? 'Livraison introuvable')),
    );

    final liv = _livraison!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Livraison ${liv.id.substring(0, 8)}'),
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _loadDetails,
           )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OfflineIndicator(
                  actionsEnAttente: 0, 
                  onSync: () {},
                ),
                
                // Carte
                SizedBox(
                  height: 300,
                  child: MapWidget(
                    center: liv.positionActuelle ?? liv.destination, // Fallback
                    zoom: 13,
                    markers: [
                      if (liv.positionActuelle != null)
                        MapMarker(
                          position: liv.positionActuelle!,
                          icon: Icons.local_shipping,
                          color: Colors.blue,
                        ),
                      MapMarker(
                        position: liv.destination,
                        icon: Icons.location_on,
                        color: Colors.red,
                      ),
                    ],
                    polyline: _route,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      _buildStatusHeader(liv),       
                      const SizedBox(height: 24),
                      
                      // Informations Client
                      _buildSectionTitle('Client'),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(liv.acheteurNom),
                        subtitle: Text(liv.acheteurTelephone),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            // TODO: Appeler
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Adresse
                      _buildSectionTitle('Destination'),
                      Row(
                        children: [
                          const Icon(Icons.map, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(liv.adresseLivraison)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Produits
                      _buildSectionTitle('Contenu'),
                      ...liv.produits.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('${p.quantite}kg ${p.nom}'),
                          ],
                        ),
                      )),
                      
                      const SizedBox(height: 100), // Espace pour boutons
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons Fixed Bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildActionButtons(liv),
          ),
          
          if (_isActionLoading)
            Container(
               color: Colors.black45,
               child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Livraison liv) {
    Color color;
    String text;
    switch(liv.statut) {
      case StatutLivraison.aVenir: color=Colors.orange; text='À venir'; break;
      case StatutLivraison.enCours: color=Colors.blue; text='En cours'; break;
      case StatutLivraison.terminee: color=Colors.green; text='Terminée'; break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          if (_distanceKm > 0 && liv.statut == StatutLivraison.enCours)
             Text('${_distanceKm.toStringAsFixed(1)} km restants'),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.bold, 
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildActionButtons(Livraison liv) {
    if (liv.statut == StatutLivraison.terminee) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-2))],
      ),
      child: SafeArea( // Sur iOS par exemple
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (liv.statut == StatutLivraison.aVenir)
              ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('DÉMARRER LA LIVRAISON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _handleAction(() => _transporteurService.demarrerLivraison(liv.id)),
              ),
              
            if (liv.statut == StatutLivraison.enCours) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('VALIDER LA LIVRAISON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _handleAction(() => _transporteurService.marquerLivree(liv.id)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Simuler Position GPS'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  // TODO: En prod, la position se met à jour automatiquement via un service background
                  // Ici simule un avancement vers destination
                  final newPos = LatLng(
                    liv.positionActuelle!.latitude + 0.001, 
                    liv.positionActuelle!.longitude + 0.001
                  );
                  _handleAction(() => _transporteurService.updatePositionGPS(
                    livraisonId: liv.id, 
                    position: newPos
                  ));
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
