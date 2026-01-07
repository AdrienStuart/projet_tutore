// ============================================
// ÉCRAN 2 : MES STOCKS
// Fichier: lib/features/producteur/screens/mes_stocks_screen.dart
// ============================================

import 'package:flutter/material.dart';
import '../../../coeur/models/stock.dart';
import '../../../coeur/models/lot.dart';
import '../../../coeur/services/producteur_service.dart';
import '../../../coeur/services/supabase_service.dart';
import '../../../coeur/utils/snackbar_helper.dart';

class MesStocksScreen extends StatefulWidget {
  const MesStocksScreen({Key? key}) : super(key: key);

  @override
  State<MesStocksScreen> createState() => _MesStocksScreenState();
}

class _MesStocksScreenState extends State<MesStocksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ProducteurService _producteurService;

  bool _isLoading = true;
  List<Stock> _stocks = [];
  List<Lot> _lots = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _producteurService = ProducteurService(SupabaseService().client);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stocks = await _producteurService.getMesStocks(avecLots: true);
      final lots = await _producteurService.getMesLots(masquerVendus: true);

      setState(() {
        _stocks = stocks;
        _lots = lots;
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
      appBar: AppBar(
        title: const Text('Mes Stocks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Par Stock', icon: Icon(Icons.inventory)),
            Tab(text: 'Par Lot', icon: Icon(Icons.qr_code)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVueStocks(),
                _buildVueLots(),
              ],
            ),
    );
  }

  Widget _buildVueStocks() {
    if (_stocks.isEmpty) {
      return const Center(
        child: Text('Aucun stock pour le moment'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final stock = _stocks[index];
          return _StockCard(stock: stock, onTap: () {
            // TODO: Naviguer vers détail stock
          });
        },
      ),
    );
  }

  Widget _buildVueLots() {
    if (_lots.isEmpty) {
      return const Center(
        child: Text('Aucun lot pour le moment'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lots.length,
        itemBuilder: (context, index) {
          final lot = _lots[index];
          return _LotCard(lot: lot);
        },
      ),
    );
  }
}

// Widget Stock Card
class _StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const _StockCard({required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stock.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildCodeCouleur(stock.qteDisponible, stock.seuilAlerte),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stock.produit?.nom ?? 'Produit inconnu',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stock.qteDisponible.toInt()}kg disponibles',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${stock.nbreLots} lot(s)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (stock.qteDisponible < stock.seuilAlerte) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Sous le seuil d\'alerte (${stock.seuilAlerte}kg)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCouleur(double qte, double seuil) {
    Color color;
    if (qte >= seuil) {
      color = Colors.green;
    } else if (qte >= seuil * 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Widget Lot Card
class _LotCard extends StatelessWidget {
  final Lot lot;

  const _LotCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    final joursRestants = lot.joursRestants ?? 0;
    Color codeCouleur;
    
    if (joursRestants > 5) {
      codeCouleur = Colors.green;
    } else if (joursRestants >= 3) {
      codeCouleur = Colors.orange;
    } else {
      codeCouleur = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: codeCouleur,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lot #${lot.codeQr}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lot.qteRestante.toInt()}kg ${lot.produit?.nom ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Parcelle: ${lot.parcelle?.nom ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Récolté: ${lot.dateRecolte.day}/${lot.dateRecolte.month}/${lot.dateRecolte.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '$joursRestants jour(s) restant(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: codeCouleur,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}