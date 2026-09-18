import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glass_container.dart';

class DashboardPieChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const DashboardPieChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ripartizione Uscite', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(color: Theme.of(context).colorScheme.primary, value: 40, title: '', radius: 30),
                        PieChartSectionData(color: Theme.of(context).colorScheme.secondary, value: 20, title: '', radius: 30),
                        PieChartSectionData(color: Color(0xFFFFFFFF), value: 15, title: '', radius: 30),
                        PieChartSectionData(color: Color(0xFFCCCCCC), value: 10, title: '', radius: 30),
                        PieChartSectionData(color: Color(0xFF999999), value: 15, title: '', radius: 30),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Theme.of(context).colorScheme.primary, 'Category', '\$222,680'),
                      SizedBox(height: 8),
                      _buildLegendItem(Theme.of(context).colorScheme.secondary, 'Category & Uncategorized', '\$75,270'),
                      SizedBox(height: 8),
                      _buildLegendItem(Color(0xFFFFFFFF), 'Environment', '\$19,630'),
                      SizedBox(height: 8),
                      _buildLegendItem(Color(0xFFCCCCCC), 'Tax Filings', '\$19,924'),
                      SizedBox(height: 8),
                      _buildLegendItem(Color(0xFF999999), 'Others', '\$16,300'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
        Text(amount, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
