import 'package:flutter/material.dart';
import 'glass_container.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = service['name']?.toString() ?? 'Servizio';
    final colorHex = service['color_hex']?.toString();
    final color = colorHex != null ? Color(int.parse(colorHex)) : Theme.of(context).colorScheme.primary; // default Yellow
    
    // For mockup purposes, assume some dummy subtitle and price
    final subtitle = 'Annual self-employment tax return'; 
    final price = '\$249.99';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)
                  ],
                ),
                child: Center(
                  child: Icon(Icons.person, color: color), // default icon
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Price Badge and actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5)),
                    color: const Color(0xFF13131A),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Elimina', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}