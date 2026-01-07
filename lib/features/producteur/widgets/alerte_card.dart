// ============================================
// ALERTE CARD
// Fichier: lib/features/producteur/widgets/alerte_card.dart
// ============================================

import 'package:flutter/material.dart';

class AlerteCard extends StatelessWidget {
  final String type;
  final String titre;
  final String message;
  final String urgence;
  final VoidCallback? onTap;

  const AlerteCard({
    Key? key,
    required this.type,
    required this.titre,
    required this.message,
    required this.urgence,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color couleur = urgence == 'Critique'
        ? Colors.red
        : urgence == 'Moyen'
            ? Colors.orange
            : Colors.blue;

    IconData icone = type == 'lot_critique'
        ? Icons.warning
        : type == 'stock_bas'
            ? Icons.inventory
            : Icons.info;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: couleur.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleur, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: couleur,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}