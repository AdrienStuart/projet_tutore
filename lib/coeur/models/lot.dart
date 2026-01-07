import 'produit.dart';
import 'parcelle.dart';

enum StatutLot { frais, critique, perime }

class Lot {
  final String id;
  final String codeQr;
  final String stockId;
  final String produitId;
  final String parcelleId;
  final String producteurId;
  final DateTime dateRecolte;
  final double qteInitiale;
  final double qteRestante;
  final StatutLot statut;
  final DateTime createdAt;
  final DateTime updatedAt;

  Produit? produit;
  Parcelle? parcelle;

  Lot({
    required this.id,
    required this.codeQr,
    required this.stockId,
    required this.produitId,
    required this.parcelleId,
    required this.producteurId,
    required this.dateRecolte,
    required this.qteInitiale,
    required this.qteRestante,
    required this.statut,
    required this.createdAt,
    required this.updatedAt,
    this.produit,
    this.parcelle,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id'],
      codeQr: json['code_qr'],
      stockId: json['stock_id'],
      produitId: json['produit_id'],
      parcelleId: json['parcelle_id'],
      producteurId: json['producteur_id'],
      dateRecolte: DateTime.parse(json['date_recolte']),
      qteInitiale: (json['qte_initiale'] as num).toDouble(),
      qteRestante: (json['qte_restante'] as num).toDouble(),
      statut: _parseStatut(json['statut']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      produit:
          json['produits'] != null ? Produit.fromJson(json['produits']) : null,
      parcelle: json['parcelles'] != null
          ? Parcelle.fromJson(json['parcelles'])
          : null,
    );
  }

  static StatutLot _parseStatut(String statut) {
    switch (statut) {
      case 'Frais':
        return StatutLot.frais;
      case 'Critique':
        return StatutLot.critique;
      case 'Perime':
        return StatutLot.perime;
      default:
        return StatutLot.frais;
    }
  }

  String get statutString {
    switch (statut) {
      case StatutLot.frais:
        return 'Frais';
      case StatutLot.critique:
        return 'Critique';
      case StatutLot.perime:
        return 'Périmé';
    }
  }

  int? get joursRestants {
    if (produit == null) return null;
    final joursPasses = DateTime.now().difference(dateRecolte).inDays;
    return produit!.dureeVie - joursPasses;
  }

  double? get pourcentageFraicheur {
    if (produit == null) return null;
    final jours = joursRestants;
    if (jours == null) return 0;
    return (jours / produit!.dureeVie * 100).clamp(0, 100);
  }

  String get codeCouleur {
    final jours = joursRestants;
    if (jours == null) return 'gris';
    if (jours > 5) return 'vert';
    if (jours >= 3) return 'orange';
    return 'rouge';
  }

  bool get estVendu => qteRestante == 0;
}
