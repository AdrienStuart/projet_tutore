// ============================================
// ÉCRAN 1 : DÉCLARER RÉCOLTE
// Fichier: lib/features/producteur/screens/declarer_recolte_screen.dart
// ============================================

import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_dropdown.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../coeur/services/producteur_service.dart';
import '../../../coeur/services/supabase_service.dart';
import '../../../coeur/models/parcelle.dart';
import '../../../coeur/models/produit.dart';
import '../../../coeur/models/stock.dart';
//import '../../../coeur/models/lot.dart';
import '../../../coeur/utils/validators.dart';
import '../../../coeur/utils/snackbar_helper.dart';
import 'qr_viewer_screen.dart';

class DeclarerRecolteScreen extends StatefulWidget {
  const DeclarerRecolteScreen({Key? key}) : super(key: key);

  @override
  State<DeclarerRecolteScreen> createState() => _DeclarerRecolteScreenState();
}

class _DeclarerRecolteScreenState extends State<DeclarerRecolteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  late final ProducteurService _producteurService;

  bool _isLoading = false;
  bool _dataLoaded = false;
  
  List<Parcelle> _parcelles = [];
  List<Produit> _produits = [];
  List<Stock> _stocks = [];
  
  Parcelle? _parcelleSelectionnee;
  Produit? _produitSelectionne;
  Stock? _stockSelectionne;
  DateTime _dateRecolte = DateTime.now();
  bool _creerNouveauStock = true;

  @override
  void initState() {
    super.initState();
    _producteurService = ProducteurService(SupabaseService().client);
    _loadData();
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final parcelles = await _producteurService.getMesParcelles();
      final produits = await _producteurService.getAllProduits();

      setState(() {
        _parcelles = parcelles;
        _produits = produits;
        _dataLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      SnackbarHelper.showError(context, 'Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStocks() async {
    if (_produitSelectionne == null) return;

    try {
      final allStocks = await _producteurService.getMesStocks();
      setState(() {
        _stocks = allStocks
            .where((s) => s.produitId == _produitSelectionne!.id)
            .toList();
      });
    } catch (e) {
      // Ignorer l'erreur silencieusement
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_parcelleSelectionnee == null) {
      SnackbarHelper.showError(context, 'Veuillez sélectionner une parcelle');
      return;
    }

    if (_produitSelectionne == null) {
      SnackbarHelper.showError(context, 'Veuillez sélectionner un produit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantite = double.parse(_quantiteController.text);
      
      final lot = await _producteurService.declarerRecolte(
        parcelleId: _parcelleSelectionnee!.id,
        produitId: _produitSelectionne!.id,
        dateRecolte: _dateRecolte,
        quantite: quantite,
        stockId: _creerNouveauStock ? null : _stockSelectionne?.id,
      );

      setState(() => _isLoading = false);

      // Afficher le QR Code immédiatement
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QRViewerScreen(lot: lot),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (e.toString().contains('hors ligne')) {
        SnackbarHelper.showInfo(
          context,
          'Récolte enregistrée hors ligne, sera synchronisée',
        );
        Navigator.pop(context);
      } else {
        SnackbarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Déclarer une Récolte'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Enregistrement...',
        child: !_dataLoaded
            ? const Center(child: CircularProgressIndicator())
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Parcelle
          CustomDropdown<Parcelle>(
            value: _parcelleSelectionnee,
            items: _parcelles
                .map((p) => DropdownMenuItem(value: p, child: Text(p.nom)))
                .toList(),
            onChanged: (p) => setState(() => _parcelleSelectionnee = p),
            label: 'Parcelle',
            prefixIcon: Icons.terrain,
          ),
          
          const SizedBox(height: 16),
          
          // Produit
          CustomDropdown<Produit>(
            value: _produitSelectionne,
            items: _produits
                .map((p) => DropdownMenuItem(value: p, child: Text(p.nom)))
                .toList(),
            onChanged: (p) {
              setState(() {
                _produitSelectionne = p;
                _stockSelectionne = null;
              });
              _loadStocks();
            },
            label: 'Produit',
            prefixIcon: Icons.grass,
          ),
          
          const SizedBox(height: 16),
          
          // Quantité
          CustomTextField(
            controller: _quantiteController,
            label: 'Quantité (kg)',
            prefixIcon: Icons.scale,
            keyboardType: TextInputType.number,
            validator: Validators.positiveNumber,
          ),
          
          const SizedBox(height: 16),
          
          // Date de récolte
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de récolte'),
            subtitle: Text(
              '${_dateRecolte.day}/${_dateRecolte.month}/${_dateRecolte.year}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),
          
          const Divider(),
          
          const SizedBox(height: 16),
          
          // Choix du stock
          const Text(
            'Assignation au stock',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Créer un stock automatique'),
            subtitle: Text(
              _produitSelectionne != null
                  ? 'Vrac ${_produitSelectionne!.nom}'
                  : 'Sélectionnez un produit',
              style: const TextStyle(fontSize: 12),
            ),
            value: true,
            groupValue: _creerNouveauStock,
            onChanged: (val) => setState(() => _creerNouveauStock = val!),
          ),
          
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Assigner à un stock existant'),
            value: false,
            groupValue: _creerNouveauStock,
            onChanged: (val) => setState(() => _creerNouveauStock = val!),
          ),
          
          if (!_creerNouveauStock) ...[
            const SizedBox(height: 8),
            CustomDropdown<Stock>(
              value: _stockSelectionne,
              items: _stocks
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                  .toList(),
              onChanged: (s) => setState(() => _stockSelectionne = s),
              label: 'Stock',
              prefixIcon: Icons.inventory,
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Bouton soumettre
          ElevatedButton.icon(
            onPressed: _soumettre,
            icon: const Icon(Icons.qr_code),
            label: const Text('Générer le Lot + QR Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateRecolte,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _dateRecolte = date);
    }
  }
}



