
import 'package:intl/intl.dart';

class Formatters {
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }
  
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  // Format montant
  static String formatMontant(double montant) {
    return NumberFormat('#,##0', 'fr_FR').format(montant) + ' FCFA';
  }
  
  // Format quantité
  static String formatQuantite(double quantite) {
    return NumberFormat('#,##0.##', 'fr_FR').format(quantite) + ' kg';
  }
  
  // Temps relatif
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return 'Il y a ${(difference.inDays / 365).floor()} an(s)';
    } else if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute(s)';
    } else {
      return 'À l\'instant';
    }
  }
}
