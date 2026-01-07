
import 'package:flutter/material.dart';

class AppConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rycqtwvzifdfvsvnusdu.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5Y3F0d3Z6aWZkZnZzdm51c2R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MzAyNjksImV4cCI6MjA4MzAwNjI2OX0.4pO10Vf32bSJvc24Zpc9OGOf71uNXFieqjF7rNObFpE',
  );
  
  // Thème
  static const Color primaryColor = Color(0xFF2E7D32); // Vert émeraude
  static const Color secondaryColor = Color(0xFF1976D2); // Bleu horizon
  static const Color accentColor = Color(0xFFFF6F00); // Orange ambre
  static const Color darkColor = Color(0xFF212121); // Noir profond
  
  // Statuts
  static const Map<String, Color> statutColors = {
    'Frais': Color(0xFF4CAF50),
    'Critique': Color(0xFFFF9800),
    'Perime': Color(0xFFF44336),
    'Brouillon': Color(0xFF9E9E9E),
    'Validee': Color(0xFF2196F3),
    'EnLivraison': Color(0xFFFF9800),
    'Livree': Color(0xFF4CAF50),
    'Cloturee': Color(0xFF4CAF50),
  };
  
  // Messages
  static const String errorGeneric = 'Une erreur s\'est produite';
  static const String errorNetwork = 'Erreur réseau. Vérifiez votre connexion';
  static const String successSaved = 'Enregistré avec succès';
}
