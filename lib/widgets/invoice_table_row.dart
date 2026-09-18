import 'package:flutter/material.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils_app.dart';

class InvoiceTableRow extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final String customerName;
  final String dateFormat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final ValueChanged<String> onStatusChanged;

  const InvoiceTableRow({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.dateFormat,
    this.isSelected = false,
    required this.onTap,
    required this.onEdit,
    required this.onDownload,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final status = invoice['status']?.toString() ?? 'PENDING';
    final isPaid = status == 'PAID' || status == 'Pagata';
    final isLate = status == 'LATE' || status == 'Da sollecitare';
    final statusColor = isPaid ? const Color(0xFF06B6D4) : (isLate ? const Color(0xFFE11D48) : Colors.orangeAccent);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE11D48).withValues(alpha: 0.05) : Colors.transparent,
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
                    border: Border.all(color: isSelected ? const Color(0xFFE11D48) : Colors.white.withValues(alpha: 0.3)),
                    color: isSelected ? const Color(0xFFE11D48) : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 20),
                
                // Invoice ID
                Expanded(
                  flex: 2,
                  child: Text(
                    '#INV-${invoice['number'] ?? '0000'}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                
                // Client Name
                Expanded(
                  flex: 3,
                  child: Text(
                    customerName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Date
                Expanded(
                  flex: 2,
                  child: Text(
                    DateUtilsApp.formatDbDate(invoice['date']?.toString(), dateFormat),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ),
                
                // Description
                Expanded(
                  flex: 3,
                  child: Text(
                    invoice['title']?.toString().isNotEmpty == true 
                        ? invoice['title'].toString() 
                        : (invoice['notes']?.toString().isNotEmpty == true ? invoice['notes'].toString() : 'Service'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Amount
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyUtils.formatEuro(double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                
                // Status Badge
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isPaid ? 'Pagata' : (isLate ? 'Da sollecitare' : 'In attesa'),
                          dropdownColor: const Color(0xFF1E1E1E),
                          icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          items: ['Pagata', 'In attesa', 'Da sollecitare'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              // map back to db status if needed, or keep Italian
                              String dbStatus = 'PENDING';
                              if (val == 'Pagata') dbStatus = 'PAID';
                              if (val == 'Da sollecitare') dbStatus = 'LATE';
                              onStatusChanged(dbStatus);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Action
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, color: Colors.amberAccent, size: 18),
                                Text(
                                  'Modifica',
                                  style: TextStyle(
                                    color: Colors.amberAccent.withValues(alpha: 0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onDownload,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download, color: Color(0xFF06B6D4), size: 18),
                                Text(
                                  'Aruba',
                                  style: TextStyle(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                                    fontSize: 10,
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
      ),
    );
  }
}
