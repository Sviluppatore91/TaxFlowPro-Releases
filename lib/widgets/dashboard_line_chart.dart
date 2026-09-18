import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';

class DashboardLineChart extends StatelessWidget {
  final Map<int, double> monthlyNet;

  const DashboardLineChart({super.key, required this.monthlyNet});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Entrate vs Uscite', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildLegendDot(AppColors.bimboYellow, 'Entrate'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.white, 'Uscite'),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${(value / 1000).toInt()}k', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        if (value >= 1 && value <= 12) {
                          return Text(months[value.toInt() - 1], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10));
                        }
                        return Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateMockData(true),
                    isCurved: true,
                    color: AppColors.bimboYellow,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: _generateMockData(false),
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }

  List<FlSpot> _generateMockData(bool isIncome) {
    // Generate dummy data based on mockup
    if (isIncome) {
      return [
        FlSpot(1, 4000), FlSpot(2, 9000), FlSpot(3, 7000), FlSpot(4, 9000),
        FlSpot(5, 12000), FlSpot(6, 9000), FlSpot(7, 18000), FlSpot(8, 11000), FlSpot(9, 15000)
      ];
    } else {
      return [
        FlSpot(1, 2000), FlSpot(2, 5000), FlSpot(3, 4000), FlSpot(4, 11000),
        FlSpot(5, 6000), FlSpot(6, 11000), FlSpot(7, 8000), FlSpot(8, 10000), FlSpot(9, 12000)
      ];
    }
  }
}
