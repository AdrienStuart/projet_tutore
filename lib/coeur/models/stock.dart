import 'produit.dart';
import 'lot.dart';

class Stock {
  final String id;
  final String producteurId;
  final String produitId;
  final String nom;
  final double qteDisponible;
  final int nbreLots;
  final double seuilAlerte;
  final DateTime dernierMiseAJour;

  Produit? produit;
  List<Lot>? lots;

  Stock({
    required this.id,
    required this.producteurId,
    required this.produitId,
    required this.nom,
    required this.qteDisponible,
    required this.nbreLots,
    required this.seuilAlerte,
    required this.dernierMiseAJour,
    this.produit,
    this.lots,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      producteurId: json['producteur_id'],
      produitId: json['produit_id'],
      nom: json['nom'],
      qteDisponible: (json['qte_disponible'] as num).toDouble(),
      nbreLots: json['nbre_lots'],
      seuilAlerte: (json['seuil_alerte'] as num).toDouble(),
      dernierMiseAJour: DateTime.parse(json['dernier_mise_a_jour']),
      produit:
          json['produits'] != null ? Produit.fromJson(json['produits']) : null,
      lots: json['lots'] != null
          ? (json['lots'] as List).map((e) => Lot.fromJson(e)).toList()
          : null,
    );
  }

  String get statutAlerte {
    if (qteDisponible < seuilAlerte * 0.5) return 'Critique';
    if (qteDisponible < seuilAlerte) return 'Bas';
    return 'Normal';
  }

  double get pourcentageRemplissage {
    return (qteDisponible / seuilAlerte * 100).clamp(0, 100);
  }
}
