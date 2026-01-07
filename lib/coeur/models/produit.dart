class Produit {
  final String id;
  final String nom;
  final String categorie;
  final int dureeVie; // en jours
  final double prixStandard;
  final DateTime createdAt;

  Produit({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.dureeVie,
    required this.prixStandard,
    required this.createdAt,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'],
      nom: json['nom'],
      categorie: json['categorie'],
      dureeVie: json['duree_vie'],
      prixStandard: (json['prix_standard'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
