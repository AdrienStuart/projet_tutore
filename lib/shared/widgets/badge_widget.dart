
import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  
  const BadgeWidget({
    required this.text,
    required this.color,
    this.icon,
    Key? key,
  }) : super(key: key);
  
  // Badges pré-définis
  factory BadgeWidget.promo(String text) {
    return BadgeWidget(
      text: text,
      color: Colors.orange,
      icon: Icons.local_fire_department,
    );
  }
  
  factory BadgeWidget.alerte() {
    return const BadgeWidget(
      text: 'Critique',
      color: Colors.red,
      icon: Icons.warning,
    );
  }
  
  factory BadgeWidget.frais() {
    return const BadgeWidget(
      text: 'Frais',
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
