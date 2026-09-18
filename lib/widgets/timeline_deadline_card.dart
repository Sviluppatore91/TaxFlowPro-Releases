import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/currency_utils.dart';
import 'glass_container.dart';

class TimelineDeadlineCard extends StatelessWidget {
  final Map<String, dynamic> deadline;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onDetails;
  final Color timelineColor;
  final bool isLast;

  const TimelineDeadlineCard({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onPay,
    required this.onDetails,
    required this.timelineColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = deadline['title']?.toString() ?? 'Scadenza';
    final amount = (deadline['amount'] as num?)?.toDouble() ?? 0.0;
    final status = deadline['status']?.toString() ?? 'PENDING';
    
    DateTime? dateFrom;
    try {
      if (deadline['date_from'] != null) {
        dateFrom = DateTime.parse(deadline['date_from']);
      }
    } catch (_) {}
    
    final dayStr = dateFrom != null ? DateFormat('dd').format(dateFrom) : '--';
    final monthStr = dateFrom != null ? DateFormat('MMM').format(dateFrom) : 'N/A';

    final isPaid = status == 'PAID';
    final isOverdue = !isPaid && dateFrom != null && dateFrom.isBefore(DateTime.now());

    Color statusColor;
    String statusLabel;
    
    if (isPaid) {
      statusColor = Colors.greenAccent;
      statusLabel = 'Pagato';
    } else if (isOverdue) {
      statusColor = Colors.redAccent;
      statusLabel = 'Scaduto';
    } else {
      statusColor = Colors.orangeAccent;
      statusLabel = 'In Sospeso';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  dayStr,
                  style: TextStyle(
                    color: timelineColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  monthStr,
                  style: TextStyle(
                    color: timelineColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: timelineColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: timelineColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            timelineColor,
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: onTap,
                child: GlassContainer(
                  borderColor: timelineColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title and Top Right Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Details row (Cliente, Stato, Priorità, Amount)
                      Row(
                        children: [
                          _buildDetailColumn('Cliente', 'Generico Srl'),
                          _buildDetailColumn('Stato', statusLabel, icon: Icons.info_outline, color: statusColor),
                          _buildDetailColumn('Priorità', isOverdue ? 'Alta' : 'Media', icon: Icons.circle, color: isOverdue ? Colors.redAccent : Colors.orangeAccent),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyUtils.formatEuro(amount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: onDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Vedi Dettagli', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: onPay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: const Color(0xFFE11D48)),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFE11D48).withValues(alpha: 0.2),
                                    const Color(0xFFE11D48).withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(isPaid ? 'Pagato' : 'Paga Ora', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, {IconData? icon, Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color ?? Colors.white),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
