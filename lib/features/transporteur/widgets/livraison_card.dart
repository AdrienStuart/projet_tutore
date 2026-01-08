import 'package:flutter/material.dart';
import '../../../coeur/models/livraison.dart';
import '../../../coeur/utils/formatters.dart';

class LivraisonCard extends StatelessWidget {
  final Livraison livraison;
  final VoidCallback onTap;

  const LivraisonCard({
    super.key,
    required this.livraison,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (livraison.statut) {
      case StatutLivraison.aVenir: return Colors.orange;
      case StatutLivraison.enCours: return Colors.blue;
      case StatutLivraison.terminee: return Colors.green;
    }
  }

  String _getStatusText() {
    switch (livraison.statut) {
      case StatutLivraison.aVenir: return 'À venir';
      case StatutLivraison.enCours: return 'En cours';
      case StatutLivraison.terminee: return 'Terminée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID et Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${livraison.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor().withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(color: _getStatusColor(), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Adresse
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      livraison.adresseLivraison,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info pied de carte: Client + Heure
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        livraison.acheteurNom,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  if (livraison.statut == StatutLivraison.enCours)
                    Text(
                      'Arrivée: ${Formatters.formatTime(livraison.dateArriveePrevue)}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                    )
                  else if (livraison.statut == StatutLivraison.terminee)
                     Text(
                      Formatters.formatDate(livraison.dateArriveeReelle ?? DateTime.now()),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
