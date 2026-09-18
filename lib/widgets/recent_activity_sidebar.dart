import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../screens/deadlines_screen.dart'; // import deadlines
import '../screens/invoices_screen.dart'; // import invoices

class RecentActivitySidebar extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const RecentActivitySidebar({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
      },
      child: GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attività Recenti', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem(
                  context: context,
                  icon: Icons.swap_horiz,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Transazione Recente',
                  subtitle: '€ 1.500',
                  time: '9:03 AM',
                  trailing: '-€ 105',
                  trailingColor: Colors.greenAccent,
                ),
                _buildActivityItem(
                  context: context,
                  icon: Icons.description,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: 'Aggiornamento Fiscale',
                  subtitle: 'Avviso di scadenza',
                  time: '9:30 AM',
                  isAlert: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 2, height: 20, color: Colors.white.withValues(alpha: 0.2)),
                      SizedBox(width: 24),
                      Text('Nuovo strumento', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ),
                _buildActivityItem(
                  context: context,
                  icon: Icons.check_circle_outline,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: 'Aggiornamento Fiscale',
                  subtitle: 'Cliente: comunicazione...',
                  time: '3:17 AM',
                ),
                _buildActivityItem(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Comunicazione Cliente',
                  subtitle: 'Cliente: comunicazione...',
                  time: '3:33 AM',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    String? trailing,
    Color? trailingColor,
    bool isAlert = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                if (trailing != null) ...[
                  SizedBox(height: 4),
                  Text(trailing, style: TextStyle(color: trailingColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                if (isAlert) ...[
                  SizedBox(height: 4),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
