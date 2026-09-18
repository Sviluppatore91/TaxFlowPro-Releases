import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../utils/currency_utils.dart';
import '../theme/app_colors.dart';

class DashboardStatCards extends StatelessWidget {
  final double totalRevenue;
  final double netIncome;

  const DashboardStatCards({
    super.key,
    required this.totalRevenue,
    required this.netIncome,
  });

  @override
  Widget build(BuildContext context) {
    // Calcolo tasse semplificato per mockup
    double taxLiability = netIncome > 0 ? netIncome * 0.22 : 0; 
    
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Entrate Totali',
            value: CurrencyUtils.formatEuro(totalRevenue),
            glowColor: AppColors.bimboYellow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Utile Netto',
            value: CurrencyUtils.formatEuro(netIncome),
            glowColor: AppColors.bimboNeonYellow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Debito Fiscale Proiettato',
            value: CurrencyUtils.formatEuro(taxLiability),
            glowColor: AppColors.bimboYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required String value, required Color glowColor}) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 10)],
            )
          ),
        ],
      ),
    );
  }
}
