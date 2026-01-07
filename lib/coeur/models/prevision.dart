import 'produit.dart';

class Prevision {
  final String id;
  final String produitId;
  final DateTime horizonTemporel;
  final double qteEstimee;
  final double indiceConfiance;
  final String source; // IA ou Admin
  final String? justification;
  final bool estActive;

  Produit? produit;

  Prevision({
    required this.id,
    required this.produitId,
    required this.horizonTemporel,
    required this.qteEstimee,
    required this.indiceConfiance,
    required this.source,
    this.justification,
    required this.estActive,
    this.produit,
  });

  factory Prevision.fromJson(Map<String, dynamic> json) {
    return Prevision(
      id: json['id'],
      produitId: json['produit_id'],
      horizonTemporel: DateTime.parse(json['horizon_temporel']),
      qteEstimee: (json['qte_estimee'] as num).toDouble(),
      indiceConfiance: (json['indice_confiance'] as num).toDouble(),
      source: json['source'],
      justification: json['justification'],
      estActive: json['est_active'] ?? true,
      produit:
          json['produits'] != null ? Produit.fromJson(json['produits']) : null,
    );
  }

  String get niveauConfiance {
    if (indiceConfiance >= 0.8) return 'Élevé';
    if (indiceConfiance >= 0.5) return 'Moyen';
    return 'Faible';
  }

  int get joursRestants {
    return horizonTemporel.difference(DateTime.now()).inDays;
  }
}
