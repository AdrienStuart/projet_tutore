// ============================================
// PARCELLE MINI CARD (pour dashboard)
// Fichier: lib/features/producteur/widgets/parcelle_mini_card.dart
// ============================================

import 'package:flutter/material.dart';
import '../../../coeur/models/parcelle.dart';

class ParcelleMiniCard extends StatelessWidget {
  final Parcelle parcelle;
  final VoidCallback? onTap;

  const ParcelleMiniCard({
    Key? key,
    required this.parcelle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.terrain,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcelle.nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${parcelle.surface} ha • ${parcelle.typeSol}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}