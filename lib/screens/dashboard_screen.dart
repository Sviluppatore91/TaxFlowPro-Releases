import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import 'package:marquee/marquee.dart';
import 'package:tax_flow_pro/utils/calculation_engine.dart';
import '../utils/currency_utils.dart';
import '../widgets/dashboard_line_chart.dart';
import '../widgets/dashboard_stat_cards.dart';
import '../widgets/dashboard_pie_chart.dart';
import '../widgets/recent_activity_sidebar.dart';
import '../widgets/pending_tasks_sidebar.dart';
import '../widgets/glass_container.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, this.role = 'User'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final int _selectedYear = DateTime.now().year;

  bool _isLoading = true;
  double _totalIn = 0;
  double _totalOut = 0;
  double _totalInLastYear = 0;
  double _totalOutLastYear = 0;

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _deadlines = [];
  List<Map<String, dynamic>> _invoices = [];
  Map<int, double> _monthlyNet = {};
  Map<String, double> _chartDataCategoria = {};
  Map<String, double> _chartDataPrestazione = {};
  Map<String, double> _chartDataFatturatoContante = {};
  Map<String, String> _categoryNames = {};
  Map<String, String> _serviceNames = {};
  Map<String, Color> _categoryColors = {};
  double _totalDeadlinesPaid = 0;
  String _chartFilter = 'Categoria'; // 'Categoria', 'Prestazione', 'Fatturato vs Contante'

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final payments = await _dbHelper.getPayments(year: _selectedYear);
      final paymentsLastYear = await _dbHelper.getPayments(
        year: _selectedYear - 1,
      );

      final deadlines = await _dbHelper.getDeadlines();
      final invoices = await _dbHelper.getInvoices();

      // Controllo aggiornamenti automatico in background
      _checkForUpdates();

      final categories = await _dbHelper.getCategories();
      Map<String, String> categoryNames = {};
      Map<String, String> categoryColorsHex = {};
      for (var c in categories) {
        categoryNames[c['id']] = c['name'];
        if (c['color_hex'] != null) {
          categoryColorsHex[c['id']] = c['color_hex'];
        }
      }
      
      final services = await _dbHelper.getServiceTypes();
      Map<String, String> serviceNames = {};
      Map<String, String> serviceColorsHex = {};
      for (var s in services) {
        serviceNames[s['id']] = s['name'];
        if (s['color_hex'] != null) {
          serviceColorsHex[s['id']] = s['color_hex'];
        }
      }

      final metrics = CalculationEngine.computeDashboardMetrics(
        payments: payments,
        paymentsLastYear: paymentsLastYear,
        invoices: invoices,
        deadlines: deadlines,
        categoryNames: categoryNames,
        serviceNames: serviceNames,
        selectedYear: _selectedYear,
      );

      final metricsLastYear = CalculationEngine.computeDashboardMetrics(
        payments: paymentsLastYear,
        paymentsLastYear: [],
        invoices: invoices,
        deadlines: deadlines,
        categoryNames: categoryNames,
        serviceNames: serviceNames,
        selectedYear: _selectedYear - 1,
      );

      Map<String, Color> tempColors = {};
      for (var catName in metrics.categoryBreakdown.keys) {
        var categoryId = categoryNames.entries.firstWhere((e) => e.value == catName, orElse: () => const MapEntry('', '')).key;
        if (categoryId.isNotEmpty && categoryColorsHex[categoryId] != null) {
          tempColors[catName] = Color(int.parse(categoryColorsHex[categoryId]!));
        }
      }
      for (var srvName in metrics.serviceBreakdown.keys) {
        var serviceId = serviceNames.entries.firstWhere((e) => e.value == srvName, orElse: () => const MapEntry('', '')).key;
        if (serviceId.isNotEmpty && serviceColorsHex[serviceId] != null) {
          tempColors[srvName] = Color(int.parse(serviceColorsHex[serviceId]!));
        }
      }
      tempColors['Fatturato'] = Theme.of(context).colorScheme.primary;
      tempColors['Contante'] = Theme.of(context).colorScheme.secondary;

      setState(() {
        _totalIn = metrics.totalIn;
        _totalOut = metrics.totalOut;
        _totalInLastYear = metricsLastYear.totalIn;
        _totalOutLastYear = metricsLastYear.totalOut;
        _payments = payments;
        _deadlines = deadlines;
        _invoices = invoices;
        _monthlyNet = metrics.monthlyNet;
        _chartDataCategoria = metrics.categoryBreakdown;
        _chartDataPrestazione = metrics.serviceBreakdown;
        _chartDataFatturatoContante = metrics.paymentMethodBreakdown;
        _categoryNames = categoryNames;
        _serviceNames = serviceNames;
        _categoryColors = tempColors;
        _totalDeadlinesPaid = metrics.totalDeadlinesPaid;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateService = UpdateService();
      final updateData = await updateService.checkForUpdate();
      if (updateData != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => UpdateDialog(
            updateData: updateData,
            updateService: updateService,
          ),
        );
      }
    } catch (e) {
      debugPrint("Errore durante il controllo aggiornamenti: $e");
    }
  }

  String _calculatePercentageChange(double current, double previous) {
    return CalculationEngine.computePercentageChange(current, previous);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : Row(
              children: [
                // Main Content Area
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 250,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Cerca...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                      prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 18),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.notifications_none, color: Colors.white.withValues(alpha: 0.7)),
                                      onPressed: () {},
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text('1', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.7), size: 18),
                                      SizedBox(width: 8),
                                      Text('Profilo', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                      SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.7), size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Line Chart
                        Expanded(
                          flex: 5,
                          child: DashboardLineChart(monthlyNet: _monthlyNet),
                        ),
                        SizedBox(height: 16),
                        // Stat Cards
                        DashboardStatCards(
                          totalRevenue: _totalIn,
                          netIncome: _totalIn - _totalOut,
                        ),
                        SizedBox(height: 16),
                        // Pie Chart
                        Expanded(
                          flex: 4,
                          child: GlassContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Ripartizione', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    DropdownButton<String>(
                                      value: _chartFilter,
                                      dropdownColor: const Color(0xFF1E1E1E),
                                      style: const TextStyle(color: Colors.white),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                      items: ['Categoria', 'Prestazione', 'Fatturato vs Contante']
                                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _chartFilter = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => _PieChartFullScreenDialog(
                                          sortedCats: _getSortedCats(),
                                          categoryColors: _categoryColors,
                                          palette: _piePalette(),
                                          title: 'Dettaglio Torta',
                                          payments: _payments,
                                          invoices: _invoices,
                                          chartFilter: _chartFilter,
                                          categoryNames: _categoryNames,
                                          serviceNames: _serviceNames,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: PieChart(
                                            PieChartData(
                                              sectionsSpace: 2,
                                              centerSpaceRadius: 40,
                                              sections: _getSortedCats().asMap().entries.map((e) {
                                                final index = e.key;
                                                final item = e.value;
                                                final color = _piePalette()[index % _piePalette().length];
                                                return PieChartSectionData(color: color, value: item.value, title: '', radius: 30);
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: _getSortedCats().take(5).toList().asMap().entries.map((e) {
                                              final index = e.key;
                                              final item = e.value;
                                              final color = _piePalette()[index % _piePalette().length];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                                          const SizedBox(width: 8),
                                                          Expanded(child: AutoScrollText(text: item.key, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text('€\${item.value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sidebar Area
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, right: 24.0, left: 0),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: RecentActivitySidebar(activities: []),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          flex: 4,
                          child: PendingTasksSidebar(tasks: []),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Dati torta condivisi ─────────────────────────────────────────────────
  List<MapEntry<String, double>> _getSortedCats() {
    Map<String, double> targetMap;
    if (_chartFilter == 'Prestazione') {
      targetMap = _chartDataPrestazione;
    } else if (_chartFilter == 'Fatturato vs Contante') {
      targetMap = _chartDataFatturatoContante;
    } else {
      targetMap = _chartDataCategoria;
    }

    return (targetMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
        .where((e) => e.value > 0)
        .toList();
  }

  List<Color> _piePalette() => [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.grey,
  ];

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('acquisti') || c.contains('spes') || c.contains('uscit') || c.contains('costi')) return Icons.shopping_cart;
    if (c.contains('incass') || c.contains('entrat') || c.contains('vendit') || c.contains('ricavi')) return Icons.attach_money;
    if (c.contains('tass') || c.contains('impost') || c.contains('iva')) return Icons.account_balance;
    if (c.contains('personale') || c.contains('dipendent') || c.contains('stipendi')) return Icons.people;
    if (c.contains('bollett') || c.contains('utenze') || c.contains('luce') || c.contains('gas')) return Icons.lightbulb;
    if (c.contains('affitt') || c.contains('locazion')) return Icons.home;
    if (c.contains('manutenzion') || c.contains('riparazion')) return Icons.build;
    if (c.contains('banca') || c.contains('commission') || c.contains('finanz')) return Icons.account_balance_wallet;
    if (c.contains('auto') || c.contains('trasport') || c.contains('carburant') || c.contains('viaggi')) return Icons.directions_car;
    if (c.contains('ristorant') || c.contains('past') || c.contains('vitto')) return Icons.restaurant;
    if (c.contains('assicu') || c.contains('polizz')) return Icons.security;
    if (c.contains('telefon') || c.contains('internet')) return Icons.phone_android;
    if (c.contains('softwar') || c.contains('abbonament') || c.contains('licenz')) return Icons.computer;
    if (c.contains('cancell') || c.contains('ufficio')) return Icons.print;
    return Icons.category;
  }

  Widget _buildBadge(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: Icon(icon, size: size * 0.6, color: Colors.black87),
    );
  }


}

class AutoScrollText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const AutoScrollText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        if (textPainter.width > constraints.maxWidth) {
          return Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 20.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 0.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          );
        } else {
          return Text(
            text,
            style: style,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}



// ═══════════════════════════════════════════════════════════════════════════════
// Dialogo full-screen torta interattiva
// ═══════════════════════════════════════════════════════════════════════════════
class _PieChartFullScreenDialog extends StatefulWidget {
  final List<MapEntry<String, double>> sortedCats;
  final Map<String, Color> categoryColors;
  final List<Color> palette;
  final String title;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> invoices;
  final String chartFilter;
  final Map<String, String> categoryNames;
  final Map<String, String> serviceNames;

  const _PieChartFullScreenDialog({
    required this.sortedCats,
    required this.categoryColors,
    required this.palette,
    required this.title,
    required this.payments,
    required this.invoices,
    required this.chartFilter,
    required this.categoryNames,
    required this.serviceNames,
  });

  @override
  State<_PieChartFullScreenDialog> createState() => _PieChartFullScreenDialogState();
}

class _PieChartFullScreenDialogState extends State<_PieChartFullScreenDialog>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = -1;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Color _colorFor(int index) =>
      widget.categoryColors[widget.sortedCats[index].key] ??
      widget.palette[index % widget.palette.length];

  void _selectSlice(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = -1;
        _animCtrl.reverse();
      } else {
        _selectedIndex = index;
        _animCtrl.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.sortedCats.fold<double>(0, (s, e) => s + e.value);
    final selected = _selectedIndex >= 0 ? widget.sortedCats[_selectedIndex] : null;
    final selectedColor = _selectedIndex >= 0 ? _colorFor(_selectedIndex) : Colors.transparent;
    final selectedPct = selected != null && total > 0
        ? (selected.value / total * 100)
        : 0.0;

    // Costruisci sezioni senza raggio fisso qui (lo calcoleremo nel LayoutBuilder)
    
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar custom ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pie_chart, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.54)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              if (_selectedIndex < 0)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Tocca una sezione per i dettagli',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),

              // ── Contenuto principale ──
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 600;

                    // Calcolo dinamico raggio (almeno 200% più grande e si adatta alla pagina)
                    double maxAvailableRadius = (isWide ? constraints.maxHeight : constraints.maxWidth) * 0.45;
                    if (maxAvailableRadius > 350) maxAvailableRadius = 350;
                    
                    // Se cliccata (pannello visibile), la torta si rimpicciolisce
                    double currentRadius = selected != null ? maxAvailableRadius * 0.65 : maxAvailableRadius;

                    final sections = List<PieChartSectionData>.generate(widget.sortedCats.length, (i) {
                      final entry = widget.sortedCats[i];
                      final color = _colorFor(i);
                      final isSelected = i == _selectedIndex;
                      final pct = total > 0 ? (entry.value / total * 100) : 0.0;

                      return PieChartSectionData(
                        color: isSelected ? color : color.withValues(alpha: 0.75),
                        value: entry.value,
                        showTitle: false,
                        radius: isSelected ? currentRadius * 1.1 : currentRadius,
                      );
                    });

                    final pieWidget = PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 0,
                        sections: sections,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            if (event is FlTapUpEvent) {
                              final idx = response?.touchedSection?.touchedSectionIndex ?? -1;
                              if (idx >= 0) _selectSlice(idx);
                            }
                          },
                        ),
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                    );

                    // Pannello dettaglio sezione selezionata
                    final detailPanel = selected != null
                        ? ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: isWide ? 24 : 0,
                                top: isWide ? 0 : 16,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: selectedColor.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header categoria
                                  Row(
                                    children: [
                                      Container(
                                        width: 14, height: 14,
                                        decoration: BoxDecoration(
                                          color: selectedColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: selectedColor.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          selected.key,
                                          style: TextStyle(
                                            color: selectedColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Importo totale
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selectedColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Totale', style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 13)),
                                        Text(
                                          CurrencyUtils.formatEuro(selected.value),
                                          style: TextStyle(
                                            color: selectedColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),

                                  // Percentuale sul totale
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('% sul totale', style: TextStyle(color: Colors.white.withValues(alpha: 0.54), fontSize: 13)),
                                        Text(
                                          '${CurrencyUtils.formatUI(selectedPct, decimals: 1)}%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),

                                  const Divider(color: Colors.white12),
                                  SizedBox(height: 8),
                                  Text(
                                    'TRANSAZIONI: ${selected.key.toUpperCase()}',
                                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),

                                  // Lista (Categorie o Transazioni filtrate)
                                  Expanded(
                                    child: _buildFilteredTransactionsList(selected.key, selectedColor),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null;

                    if (isWide) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: pieWidget),
                            if (detailPanel != null)
                              Expanded(flex: 1, child: detailPanel),
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: detailPanel != null
                                  ? constraints.maxHeight * 0.42
                                  : constraints.maxHeight * 0.7,
                              child: pieWidget,
                            ),
                            if (detailPanel != null)
                              Expanded(child: detailPanel),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),

              // ── Legenda scrollabile in fondo (se nessuna selezione) ──
              if (_selectedIndex < 0)
                Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16, top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.sortedCats.length,
                    itemBuilder: (_, i) {
                      final entry = widget.sortedCats[i];
                      final color = _colorFor(i);
                      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                      return GestureDetector(
                        onTap: () => _selectSlice(i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    entry.key.length > 14 ? '${entry.key.substring(0, 12)}…' : entry.key,
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '€ ${CurrencyUtils.formatUI(entry.value, decimals: 0)}  •  ${CurrencyUtils.formatUI(pct, decimals: 1)}%',
                                style: TextStyle(color: color, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions(String sliceKey) {
    if (widget.chartFilter == 'Categoria') {
      return widget.payments.where((p) {
        final catId = p['category_id']?.toString();
        if (catId == null) return false;
        final name = widget.categoryNames[catId] ?? 'Sconosciuta';
        return name == sliceKey;
      }).toList();
    } else if (widget.chartFilter == 'Prestazione') {
      return widget.payments.where((p) {
        final srvId = p['service_id']?.toString();
        if (srvId == null) return false;
        final name = widget.serviceNames[srvId] ?? 'Sconosciuta';
        return name == sliceKey;
      }).toList();
    } else if (widget.chartFilter == 'Fatturato vs Contante') {
      if (sliceKey.toLowerCase().contains('contant')) {
        return widget.payments.where((p) {
          final isIN = p['type'] == 'IN';
          final method = (p['payment_method']?.toString() ?? '').toLowerCase();
          return isIN && method.contains('contant');
        }).toList();
      } else {
        return widget.invoices.toList();
      }
    }
    return [];
  }

  Widget _buildFilteredTransactionsList(String sliceKey, Color color) {
    final list = _getFilteredTransactions(sliceKey);
    
    if (list.isEmpty) {
      return Center(
        child: Text('Nessuna transazione trovata.', style: TextStyle(color: Colors.white54)),
      );
    }

    list.sort((a, b) {
      final da = a['date']?.toString() ?? '';
      final db = b['date']?.toString() ?? '';
      return db.compareTo(da);
    });

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isInvoice = item.containsKey('number');
        
        String title = '';
        String subtitle = '';
        String amount = '';

        if (isInvoice) {
          title = 'Fattura n. ${item['number'] ?? '-'}';
          subtitle = item['date'] ?? '';
          amount = '€ ${item['amount']?.toString() ?? '0.00'}';
        } else {
          bool isIN = item['type'] == 'IN';
          title = item['payment_method'] ?? (isIN ? 'Incasso' : 'Spesa');
          final customerName = item['customer_name']?.toString() ?? '';
          final serviceName = item['service_name']?.toString() ?? '';
          subtitle = [item['date'], if (customerName.isNotEmpty) customerName, if (serviceName.isNotEmpty) serviceName].join(' • ');
          amount = '€ ${item['amount']?.toString() ?? '0.00'}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}