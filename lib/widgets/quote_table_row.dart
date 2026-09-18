import 'package:flutter/material.dart';

class QuoteTableRow extends StatelessWidget {
  final Map<String, dynamic> quote;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const QuoteTableRow({
    super.key,
    required this.quote,
    this.isSelected = false,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bool accepted = quote['accepted'] == true;
    final bool rejected = quote['rejected'] == true;
    final String statusText = accepted ? 'ACCEPTED' : (rejected ? 'REJECTED' : 'PENDING');
    final Color statusColor = accepted ? const Color(0xFF10B981) : (rejected ? const Color(0xFFE11D48) : const Color(0xFFF59E0B));
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.3)),
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 20),
                
                // Quote ID
                Expanded(
                  flex: 2,
                  child: Text(
                    '#Q-${quote['serial_number'] ?? '000'}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                
                // File Name
                Expanded(
                  flex: 3,
                  child: Text(
                    quote['file_name']?.toString() ?? 'Sconosciuto',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Date
                Expanded(
                  flex: 2,
                  child: Text(
                    quote['created_at'] != null ? quote['created_at'].toString().split('T').first : '-',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ),
                
                // Status Badge
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Actions (Accept/Reject/Delete/Download)
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildAction(Icons.check, Colors.greenAccent, 'Accetta', onAccept),
                      const SizedBox(width: 8),
                      _buildAction(Icons.close, Colors.orangeAccent, 'Rifiuta', onReject),
                      const SizedBox(width: 8),
                      _buildAction(Icons.download, Theme.of(context).colorScheme.primary, 'Download', onDownload),
                      const SizedBox(width: 8),
                      _buildAction(Icons.delete, Colors.redAccent, 'Elimina', onDelete),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, Color color, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            Text(
              label,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
