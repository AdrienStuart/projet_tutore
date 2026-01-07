// ============================================
// PREVISION CARD
// Fichier: lib/features/producteur/widgets/prevision_card.dart
// ============================================

import 'package:flutter/material.dart';
import '../../../coeur/models/prevision.dart';

class PrevisionCard extends StatelessWidget {
  final Prevision prevision;

  const PrevisionCard({
    Key? key,
    required this.prevision,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final couleurConfiance = prevision.indiceConfiance >= 0.8
        ? Colors.green
        : prevision.indiceConfiance >= 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32),
            const Color(0xFF1976D2).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prevision.produit?.nom ?? 'Produit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quantité estimée
          Text(
            '${prevision.qteEstimee.toInt()} kg',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Demande prévue dans ${prevision.joursRestants} jour(s)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          const Spacer(),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: couleurConfiance.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: couleurConfiance),
                ),
                child: Text(
                  prevision.niveauConfiance,
                  style: TextStyle(
                    fontSize: 12,
                    color: couleurConfiance,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                prevision.source,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}