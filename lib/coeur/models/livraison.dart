// ============================================
// MODEL LIVRAISON
// ============================================
// Représente une livraison dans le système AgroNet
// Correspond à la table 'livraisons' dans Supabase
// ============================================

import 'package:latlong2/latlong.dart';
import 'dart:convert';

/// Statut d'une livraison (lifecycle)
enum StatutLivraison {
  aVenir,    // date_depart > NOW()
  enCours,   // date_depart <= NOW() ET date_arrivee_reelle = NULL
  terminee;  // date_arrivee_reelle != NULL

  /// Parse depuis une string (depuis DB ou cache)
  static StatutLivraison fromString(String value) {
    return StatutLivraison.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StatutLivraison.aVenir,
    );
  }
}

/// Model complet d'une livraison
/// Utilisé par le module Transporteur
class Livraison {
  // ============================================
  // CHAMPS PRINCIPAUX (Table livraisons)
  // ============================================
  
  final String id;                    // UUID livraison
  final String commandeId;            // UUID commande liée
  final String transporteurId;        // UUID transporteur (moi)
  
  final DateTime datePriseEnCharge;   // Quand j'ai accepté
  final DateTime dateDepart;          // Quand je pars (peut être futur)
  final DateTime dateArriveePrevue;   // Estimation arrivée
  final DateTime? dateArriveeReelle;  // NULL si pas encore livrée
  
  final LatLng? positionActuelle;     // Ma position GPS actuelle (ou null)

  // ============================================
  // CHAMPS ÉTENDUS (Depuis commandes + vue)
  // ============================================
  
  final double montantTotal;          // Montant commande
  final String adresseLivraison;      // Adresse texte
  final LatLng destination;           // Coordonnées GPS destination
  
  final String acheteurNom;           // Nom client
  final String acheteurTelephone;     // Tél client
  
  final List<ProduitLivraison> produits;  // Liste produits à livrer
  
  // ============================================
  // CHAMPS CALCULÉS (Frontend)
  // ============================================
  
  /// Distance restante en km (calculée via maps_service)
  /// NULL si pas encore de position actuelle
  final double? distanceRestanteKm;
  
  /// Retard/avance en minutes (négatif = avance, positif = retard)
  final double? minutesRetard;

  // ============================================
  // CONSTRUCTOR
  // ============================================
  
  const Livraison({
    required this.id,
    required this.commandeId,
    required this.transporteurId,
    required this.datePriseEnCharge,
    required this.dateDepart,
    required this.dateArriveePrevue,
    this.dateArriveeReelle,
    this.positionActuelle,
    required this.montantTotal,
    required this.adresseLivraison,
    required this.destination,
    required this.acheteurNom,
    required this.acheteurTelephone,
    required this.produits,
    this.distanceRestanteKm,
    this.minutesRetard,
  });

  // ============================================
  // FACTORY : Depuis Supabase (vue v_mes_livraisons)
  // ============================================
  
  /// Parse une row depuis la vue v_mes_livraisons
  /// Cette vue contient déjà les JOINs nécessaires
  factory Livraison.fromSupabase(Map<String, dynamic> json) {
    return Livraison(
      id: json['livraison_id'] as String,
      commandeId: json['commande_id'] as String,
      transporteurId: json['transporteur_id'] as String? ?? '',
      
      datePriseEnCharge: DateTime.parse(json['date_prise_en_charge'] as String),
      dateDepart: DateTime.parse(json['date_depart'] as String),
      dateArriveePrevue: DateTime.parse(json['date_arrivee_prevue'] as String),
      dateArriveeReelle: json['date_arrivee_reelle'] != null 
          ? DateTime.parse(json['date_arrivee_reelle'] as String)
          : null,
      
      // Position actuelle (GeoJSON depuis PostGIS)
      positionActuelle: json['ma_position'] != null 
          ? _parseGeoJSON(json['ma_position'])
          : null,
      
      montantTotal: (json['montant_total'] as num).toDouble(),
      adresseLivraison: json['adresse_livraison'] as String,
      
      // Destination (GeoJSON depuis PostGIS)
      destination: _parseGeoJSON(json['destination']),
      
      acheteurNom: json['acheteur_nom'] as String,
      acheteurTelephone: json['acheteur_telephone'] as String,
      
      // Produits (JSON array)
      produits: (json['produits'] as List?)
          ?.map((p) => ProduitLivraison.fromJson(p))
          .toList() ?? [],
      
      // Champs calculés par la vue
      distanceRestanteKm: json['distance_restante_km'] != null 
          ? (json['distance_restante_km'] as num).toDouble()
          : null,
      minutesRetard: json['minutes_retard'] != null 
          ? (json['minutes_retard'] as num).toDouble()
          : null,
    );
  }

  // ============================================
  // FACTORY : Depuis cache local (Hive)
  // ============================================
  
  /// Parse depuis le cache Hive (format simple Map)
  factory Livraison.fromJson(Map<String, dynamic> json) {
    return Livraison(
      id: json['id'] as String,
      commandeId: json['commande_id'] as String,
      transporteurId: json['transporteur_id'] as String,
      
      datePriseEnCharge: DateTime.parse(json['date_prise_en_charge'] as String),
      dateDepart: DateTime.parse(json['date_depart'] as String),
      dateArriveePrevue: DateTime.parse(json['date_arrivee_prevue'] as String),
      dateArriveeReelle: json['date_arrivee_reelle'] != null 
          ? DateTime.parse(json['date_arrivee_reelle'] as String)
          : null,
      
      positionActuelle: json['position_actuelle'] != null 
          ? LatLng(
              json['position_actuelle']['lat'] as double,
              json['position_actuelle']['lng'] as double,
            )
          : null,
      
      montantTotal: (json['montant_total'] as num).toDouble(),
      adresseLivraison: json['adresse_livraison'] as String,
      destination: LatLng(
        json['destination']['lat'] as double,
        json['destination']['lng'] as double,
      ),
      
      acheteurNom: json['acheteur_nom'] as String,
      acheteurTelephone: json['acheteur_telephone'] as String,
      
      produits: (json['produits'] as List?)
          ?.map((p) => ProduitLivraison.fromJson(p))
          .toList() ?? [],
      
      distanceRestanteKm: json['distance_restante_km'] as double?,
      minutesRetard: json['minutes_retard'] as double?,
    );
  }

  // ============================================
  // SERIALISATION (Pour Hive)
  // ============================================
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'transporteur_id': transporteurId,
      'date_prise_en_charge': datePriseEnCharge.toIso8601String(),
      'date_depart': dateDepart.toIso8601String(),
      'date_arrivee_prevue': dateArriveePrevue.toIso8601String(),
      'date_arrivee_reelle': dateArriveeReelle?.toIso8601String(),
      'position_actuelle': positionActuelle != null 
          ? {'lat': positionActuelle!.latitude, 'lng': positionActuelle!.longitude}
          : null,
      'montant_total': montantTotal,
      'adresse_livraison': adresseLivraison,
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      'acheteur_nom': acheteurNom,
      'acheteur_telephone': acheteurTelephone,
      'produits': produits.map((p) => p.toJson()).toList(),
      'distance_restante_km': distanceRestanteKm,
      'minutes_retard': minutesRetard,
    };
  }

  // ============================================
  // HELPERS
  // ============================================
  
  /// Parse un GeoJSON PostGIS vers LatLng
  /// Format: {"type":"Point","coordinates":[lng, lat]}
  static LatLng _parseGeoJSON(dynamic geoJson) {
    if (geoJson is String) {
      geoJson = jsonDecode(geoJson);
    }
    final coords = geoJson['coordinates'] as List;
    return LatLng(coords[1] as double, coords[0] as double); // [lng, lat] -> LatLng(lat, lng)
  }

  /// Statut calculé selon les dates
  StatutLivraison get statut {
    if (dateArriveeReelle != null) return StatutLivraison.terminee;
    if (DateTime.now().isBefore(dateDepart)) return StatutLivraison.aVenir;
    return StatutLivraison.enCours;
  }

  /// Poids total en kg
  double get poidsTotalKg => produits.fold(0.0, (sum, p) => sum + p.quantite);

  /// Est en retard ? (seulement si en cours ou terminée)
  bool get estEnRetard {
    if (statut == StatutLivraison.aVenir) return false;
    if (dateArriveeReelle != null) {
      return dateArriveeReelle!.isAfter(dateArriveePrevue);
    }
    return DateTime.now().isAfter(dateArriveePrevue);
  }

  /// CopyWith pour immutabilité
  Livraison copyWith({
    String? id,
    String? commandeId,
    String? transporteurId,
    DateTime? datePriseEnCharge,
    DateTime? dateDepart,
    DateTime? dateArriveePrevue,
    DateTime? dateArriveeReelle,
    LatLng? positionActuelle,
    double? montantTotal,
    String? adresseLivraison,
    LatLng? destination,
    String? acheteurNom,
    String? acheteurTelephone,
    List<ProduitLivraison>? produits,
    double? distanceRestanteKm,
    double? minutesRetard,
  }) {
    return Livraison(
      id: id ?? this.id,
      commandeId: commandeId ?? this.commandeId,
      transporteurId: transporteurId ?? this.transporteurId,
      datePriseEnCharge: datePriseEnCharge ?? this.datePriseEnCharge,
      dateDepart: dateDepart ?? this.dateDepart,
      dateArriveePrevue: dateArriveePrevue ?? this.dateArriveePrevue,
      dateArriveeReelle: dateArriveeReelle ?? this.dateArriveeReelle,
      positionActuelle: positionActuelle ?? this.positionActuelle,
      montantTotal: montantTotal ?? this.montantTotal,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      destination: destination ?? this.destination,
      acheteurNom: acheteurNom ?? this.acheteurNom,
      acheteurTelephone: acheteurTelephone ?? this.acheteurTelephone,
      produits: produits ?? this.produits,
      distanceRestanteKm: distanceRestanteKm ?? this.distanceRestanteKm,
      minutesRetard: minutesRetard ?? this.minutesRetard,
    );
  }
}

// ============================================
// MODEL PRODUIT DANS LIVRAISON (Simplifié)
// ============================================

class ProduitLivraison {
  final String nom;       // Nom produit (ex: "Tomates")
  final double quantite;  // Quantité en kg

  const ProduitLivraison({
    required this.nom,
    required this.quantite,
  });

  factory ProduitLivraison.fromJson(Map<String, dynamic> json) {
    return ProduitLivraison(
      nom: json['produit'] as String,
      quantite: (json['quantite'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit': nom,
      'quantite': quantite,
    };
  }
}

// ============================================
// MODEL COMMANDE DISPONIBLE (Pour liste)
// ============================================

/// Commande disponible à prendre (status = Validee)
/// Correspond à la vue v_livraisons_disponibles
class CommandeDisponible {
  final String id;
  final DateTime dateCmd;
  final double montantTotal;
  final String adresseLivraison;
  final LatLng coordonneesLivraison;
  
  final String acheteurNom;
  final String acheteurTelephone;
  
  final List<ProduitLivraison> produits;
  final double poidsTotalKg;
  
  final int minutesDepuisValidation;  // Ancienneté (priorité)
  final int priorite;                 // Rang dans la file (1 = premier)

  const CommandeDisponible({
    required this.id,
    required this.dateCmd,
    required this.montantTotal,
    required this.adresseLivraison,
    required this.coordonneesLivraison,
    required this.acheteurNom,
    required this.acheteurTelephone,
    required this.produits,
    required this.poidsTotalKg,
    required this.minutesDepuisValidation,
    required this.priorite,
  });

  /// Parse depuis v_livraisons_disponibles
  factory CommandeDisponible.fromSupabase(Map<String, dynamic> json) {
    return CommandeDisponible(
      id: json['commande_id'] as String,
      dateCmd: DateTime.parse(json['date_cmd'] as String),
      montantTotal: (json['montant_total'] as num).toDouble(),
      adresseLivraison: json['adresse_livraison'] as String,
      coordonneesLivraison: Livraison._parseGeoJSON(json['coordonnees_livraison']),
      acheteurNom: json['acheteur_nom'] as String,
      acheteurTelephone: json['acheteur_telephone'] as String,
      produits: (json['produits'] as List?)
          ?.map((p) => ProduitLivraison.fromJson(p))
          .toList() ?? [],
      poidsTotalKg: (json['poids_total_kg'] as num).toDouble(),
      minutesDepuisValidation: (json['minutes_depuis_validation'] as num).toInt(),
      priorite: (json['priorite'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_cmd': dateCmd.toIso8601String(),
      'montant_total': montantTotal,
      'adresse_livraison': adresseLivraison,
      'coordonnees_livraison': {
        'lat': coordonneesLivraison.latitude,
        'lng': coordonneesLivraison.longitude,
      },
      'acheteur_nom': acheteurNom,
      'acheteur_telephone': acheteurTelephone,
      'produits': produits.map((p) => p.toJson()).toList(),
      'poids_total_kg': poidsTotalKg,
      'minutes_depuis_validation': minutesDepuisValidation,
      'priorite': priorite,
    };
  }
}
