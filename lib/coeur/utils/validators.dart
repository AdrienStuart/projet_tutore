
class Validators {
  // Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }
  
  // Mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    return null;
  }
  
  // Téléphone togolais
  static String? telephone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Téléphone requis';
    }
    final phoneRegex = RegExp(r'^\+228\d{8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format: +228XXXXXXXX';
    }
    return null;
  }
  
  // Requis
  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$field est requis';
    }
    return null;
  }
  
  // Nombre positif
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Valeur requise';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return 'Doit être un nombre positif';
    }
    return null;
  }
}
