enum NatureActivite { semis, irrigation, traitement, recolte, autre }

class Activite {
  final String id;
  final String parcelleId;
  final DateTime dateAction;
  final String description;
  final NatureActivite nature;
  final Map<String, dynamic>? intrantUtilise;
  final DateTime createdAt;

  Activite({
    required this.id,
    required this.parcelleId,
    required this.dateAction,
    required this.description,
    required this.nature,
    this.intrantUtilise,
    required this.createdAt,
  });

  factory Activite.fromJson(Map<String, dynamic> json) {
    return Activite(
      id: json['id'],
      parcelleId: json['parcelle_id'],
      dateAction: DateTime.parse(json['date_action']),
      description: json['description'],
      nature: _parseNature(json['nature']),
      intrantUtilise: json['intrant_utilise'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static NatureActivite _parseNature(String nature) {
    switch (nature) {
      case 'Semis':
        return NatureActivite.semis;
      case 'Irrigation':
        return NatureActivite.irrigation;
      case 'Traitement':
        return NatureActivite.traitement;
      case 'Recolte':
        return NatureActivite.recolte;
      default:
        return NatureActivite.autre;
    }
  }

  String get natureString {
    switch (nature) {
      case NatureActivite.semis:
        return 'Semis';
      case NatureActivite.irrigation:
        return 'Irrigation';
      case NatureActivite.traitement:
        return 'Traitement';
      case NatureActivite.recolte:
        return 'Récolte';
      case NatureActivite.autre:
        return 'Autre';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'parcelle_id': parcelleId,
      'date_action': dateAction.toIso8601String().split('T')[0],
      'description': description,
      'nature': natureString,
      'intrant_utilise': intrantUtilise,
    };
  }
}
