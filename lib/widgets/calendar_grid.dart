import 'package:flutter/material.dart';
import 'glass_container.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, List<Map<String, dynamic>>> events;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    
    // Weekday 1 = Monday, 7 = Sunday
    final firstWeekday = firstDayOfMonth.weekday;
    final totalCells = 42; // 6 rows of 7 days
    
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            // Calculate actual date for this cell
            final dayOffset = index - (firstWeekday - 1);
            
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              // Empty cell for previous/next month days
              return const SizedBox();
            }
            
            final date = DateTime(currentMonth.year, currentMonth.month, dayOffset + 1);
            final isSelected = DateUtils.isSameDay(date, selectedDate);
            final dayEvents = _getEventsForDay(date);
            
            // Determine colors
            final hasEvents = dayEvents.isNotEmpty;
            final Color eventColor = hasEvents 
                ? (dayEvents.first['color'] as Color? ?? const Color(0xFF06B6D4)) // Default Cyan
                : Colors.transparent;
                
            final String eventLabel = hasEvents ? (dayEvents.first['title']?.toString() ?? '') : '';

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                borderColor: isSelected || hasEvents ? eventColor : Colors.white.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected || hasEvents ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isSelected || hasEvents ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (hasEvents) ...[
                      Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: eventColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: eventColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
    // Basic date matching
    final match = events.keys.where((k) => DateUtils.isSameDay(k, date));
    if (match.isEmpty) return [];
    return events[match.first] ?? [];
  }
}
