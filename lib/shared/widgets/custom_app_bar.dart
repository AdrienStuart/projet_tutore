
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  
  const CustomAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: const Color(0xFF2E7D32), // Vert émeraude
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      leading: leading ?? (showBackButton ? null : const SizedBox()),
      actions: actions,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}