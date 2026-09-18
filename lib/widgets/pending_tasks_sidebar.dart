import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../screens/deadlines_screen.dart'; // import deadlines

class PendingTasksSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const PendingTasksSidebar({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DeadlinesScreen()));
      },
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attività in Sospeso', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildTaskItem(context, 'Scadenza Imminente', true, 'Priorità', Theme.of(context).colorScheme.primary, 1.0),
                  _buildTaskItem(context, 'Azioni da completare', false, '', Colors.transparent, 0.7),
                  _buildTaskItem(context, 'Scadenza Pagamento', false, 'Alta', Theme.of(context).colorScheme.secondary, 0.4),
                  _buildTaskItem(context, 'Scadenza Documenti', false, 'Alta', Color(0xFFFF8C00), 0.8),
                  _buildTaskItem(context, 'Registrazione attività', false, 'Alta', Color(0xFFFF3B30), 0.3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, String title, bool isChecked, String badgeText, Color badgeColor, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (badgeText.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10)),
                ),
            ],
          ),
          if (!isChecked && progress > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 32),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
