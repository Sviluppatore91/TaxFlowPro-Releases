import 'package:flutter/material.dart';
import 'glass_container.dart';

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color? glowColor;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? Theme.of(context).colorScheme.primary;
    final title = note['title']?.toString() ?? 'Senza Titolo';
    final date = note['update_date'] ?? note['creation_date'] ?? '';
    final type = note['type']?.toString() ?? 'TEXT';
    
    // Parse time if possible or just use a dummy like '11:30 AM' to match UI
    final String timeStr = '11:30 AM';
    
    // For mockup visuals, adding a dummy price or tag if needed
    final String dummyPrice = '';
    final String dummyCategory = type == 'CHECKLIST' ? 'Task List' : 'General Note';
    final List<String> dummyTags = ['#Note'];

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderColor: effectiveGlowColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Let it adapt to grid
          children: [
            // Header: Icon + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveGlowColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'CHECKLIST' ? Icons.checklist : Icons.notes,
                    color: effectiveGlowColor,
                    size: 20,
                  ),
                ),
                Text(
                  date.isNotEmpty ? date.split('T').first : timeStr,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Category subtitle
            Text(
              dummyCategory,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            
            if (dummyPrice.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                dummyPrice,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
            
            const SizedBox(height: 16),
            const Spacer(),
            
            // Tags and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 6,
                  children: dummyTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                    ),
                  )).toList(),
                ),
                InkWell(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: 0.5), size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}