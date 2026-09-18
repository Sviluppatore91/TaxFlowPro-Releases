import 'package:flutter/material.dart';
import 'glass_container.dart';

class DailyOverview extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> events;
  final VoidCallback onAddEvent;

  const DailyOverview({
    super.key,
    required this.date,
    required this.events,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riepilogo Giornaliero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.5), size: 20),
                  onPressed: onAddEvent,
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Nessun evento per questa data.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                final title = event['title']?.toString() ?? 'Evento';
                final color = event['color'] as Color? ?? const Color(0xFFE11D48); // default pink
                final time = '10:00 AM'; // Dummy for mockup
                
                final isCompleted = event['is_completed'] == 1 || event['is_completed'] == true;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.transparent : color,
                          shape: BoxShape.circle,
                          border: isCompleted ? Border.all(color: color) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isCompleted ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                            fontSize: 14,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
