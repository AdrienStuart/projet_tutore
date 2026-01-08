import 'package:flutter/material.dart';
import '../../../coeur/models/livraison.dart';
import '../../../coeur/utils/formatters.dart';

class CommandeCard extends StatelessWidget {
  final CommandeDisponible commande;
  final VoidCallback onAccept;
  final bool isLoading;

  const CommandeCard({
    super.key,
    required this.commande,
    required this.onAccept,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Montant et Distance (si dispo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatMontant(commande.montantTotal * 0.10), // Gain transporteur 10%
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${commande.poidsTotalKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Adresse
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    commande.adresseLivraison,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Produits (Aperçu)
            Text(
              commande.produits.map((p) => '${p.quantite}kg ${p.nom}').join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            
            // Bouton Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('ACCEPTER LA LIVRAISON'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
