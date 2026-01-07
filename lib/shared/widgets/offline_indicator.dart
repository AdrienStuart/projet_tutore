
import 'package:flutter/material.dart';

class OfflineIndicator extends StatelessWidget {
  final int actionsEnAttente;
  final VoidCallback onSync;
  final bool isSyncing;
  
  const OfflineIndicator({
    required this.actionsEnAttente,
    required this.onSync,
    this.isSyncing = false,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (actionsEnAttente == 0) return const SizedBox.shrink();
    
    return Container(
      color: Colors.orange[100],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$actionsEnAttente action(s) en attente de synchronisation',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onSync,
              child: const Text('Synchroniser'),
            ),
        ],
      ),
    );
  }
}
