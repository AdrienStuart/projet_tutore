// ============================================
// ÉCRAN 3 : PARCELLES
// Fichier: lib/features/producteur/screens/parcelles_screen.dart
// ============================================

import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../coeur/services/producteur_service.dart';
import '../../../coeur/services/supabase_service.dart';
import '../../../coeur/models/parcelle.dart';
import '../../../coeur/utils/snackbar_helper.dart';

class ParcellesScreen extends StatefulWidget {
  const ParcellesScreen({Key? key}) : super(key: key);

  @override
  State<ParcellesScreen> createState() => _ParcellesScreenState();
}

class _ParcellesScreenState extends State<ParcellesScreen> {
  late final ProducteurService _producteurService;
  bool _isLoading = true;
  List<Parcelle> _parcelles = [];

  @override
  void initState() {
    super.initState();
    _producteurService = ProducteurService(SupabaseService().client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final parcelles = await _producteurService.getMesParcelles();
      setState(() {
        _parcelles = parcelles;
        _isLoading = false;
      });
    } catch (e) {
      SnackbarHelper.showError(context, 'Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes Parcelles'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parcelles.isEmpty
              ? const Center(child: Text('Aucune parcelle assignée'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parcelles.length,
                    itemBuilder: (context, index) {
                      final parcelle = _parcelles[index];
                      return _ParcelleCard(parcelle: parcelle);
                    },
                  ),
                ),
    );
  }
}

class _ParcelleCard extends StatelessWidget {
  final Parcelle parcelle;

  const _ParcelleCard({required this.parcelle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parcelle.nom,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.landscape, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${parcelle.surface} ha'),
                const SizedBox(width: 16),
                const Icon(Icons.terrain, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(parcelle.typeSol),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Ajouter activité
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter une activité'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}