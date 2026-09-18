import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'glass_container.dart';

class ClientCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;

  const ClientCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Generate some fake UI data to match mockup for now if missing
    final String accountStatus = (customer.vatNumber?.isNotEmpty ?? false) ? 'Active' : 'Pending';
    final Color statusColor = accountStatus == 'Active' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final String nextDueDate = '15 Oct'; // Mock
    final String recentActivity = 'Tax filing 15 ago'; // Mock

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          borderColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                      image: customer.logoPath != null && File(customer.logoPath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(customer.logoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: customer.logoPath == null || !File(customer.logoPath!).existsSync()
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.vatNumber ?? customer.taxCode ?? 'No VAT/CF',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.54),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      accountStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              
              // Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Client ID', '#${customer.id?.substring(0, 6).toUpperCase() ?? "000"}'),
                  _buildInfoColumn('Next Due Date', nextDueDate),
                  _buildInfoColumn('Account Status', accountStatus, valueColor: statusColor),
                ],
              ),
              
              const SizedBox(height: 16),
              // Activity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Activity', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Recent Activity - $recentActivity', style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionIcon(Icons.person_outline, 'View Profile', onTap),
                  _buildActionIcon(Icons.mail_outline, 'Send Message', () {}),
                  _buildActionIcon(Icons.upload_file, 'Upload Docs', () {}),
                  _buildActionIcon(Icons.more_horiz, 'More', () {}),
                  // Manteniamo le azioni originali di modifica ed eliminazione
                  _buildActionIcon(Icons.edit, 'Edit', onEdit, color: Theme.of(context).colorScheme.primary),
                  _buildActionIcon(Icons.delete_outline, 'Delete', onDelete, color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onPressed, {Color? color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}