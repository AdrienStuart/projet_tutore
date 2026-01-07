// ============================================
// QR VIEWER SCREEN
// Fichier: lib/features/producteur/screens/qr_viewer_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../coeur/models/lot.dart';

class QRViewerScreen extends StatelessWidget {
  final Lot lot;

  const QRViewerScreen({
    Key? key,
    required this.lot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOffline = lot.codeQr.startsWith('OFFLINE');

    return Scaffold(
      appBar: const CustomAppBar(title: 'QR Code du Lot'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge offline si nécessaire
              if (isOffline) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        '⏳ En attente de synchronisation',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // QR Code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: lot.codeQr,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),

              const SizedBox(height: 24),

              // Code QR en texte
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  lot.codeQr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // Informations du lot
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations du lot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Produit',
                        lot.produit?.nom ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Parcelle',
                        lot.parcelle?.nom ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Quantité',
                        '${lot.qteInitiale.toInt()} kg',
                      ),
                      _buildInfoRow(
                        'Date de récolte',
                        '${lot.dateRecolte.day}/${lot.dateRecolte.month}/${lot.dateRecolte.year}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _partager(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _imprimer(context),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Retour
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour au dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _partager(BuildContext context) async {
    try {
      await Share.share(
        'Lot AgroNet\n'
        'Code QR: ${lot.codeQr}\n'
        'Produit: ${lot.produit?.nom ?? 'N/A'}\n'
        'Quantité: ${lot.qteInitiale.toInt()}kg\n'
        'Date: ${lot.dateRecolte.day}/${lot.dateRecolte.month}/${lot.dateRecolte.year}',
        subject: 'Lot ${lot.codeQr}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de partage: $e')),
      );
    }
  }

  Future<void> _imprimer(BuildContext context) async {
    // TODO: Implémenter impression avec printing package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'impression à venir'),
      ),
    );
  }
}







