import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final bool isDesktop;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppThemeProvider>(context);

    Widget content = Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.blender, color: Theme.of(context).colorScheme.secondary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text(
                        'BIMBO',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                      Text(
                        'MIXER',
                        style: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _DrawerItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                isSelected: currentIndex == 0,
                onTap: () => _handleItemTap(context, 0),
              ),
              _DrawerItem(
                icon: Icons.swap_horiz_outlined,
                title: 'Movimenti',
                isSelected: currentIndex == 1,
                onTap: () => _handleItemTap(context, 1),
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                title: 'Fatture',
                isSelected: currentIndex == 2,
                onTap: () => _handleItemTap(context, 2),
              ),
              _DrawerItem(
                icon: Icons.calendar_today_outlined,
                title: 'Scadenze',
                isSelected: currentIndex == 3,
                onTap: () => _handleItemTap(context, 3),
              ),
              _DrawerItem(
                icon: Icons.note_outlined,
                title: 'Note',
                isSelected: currentIndex == 4,
                onTap: () => _handleItemTap(context, 4),
              ),
              _DrawerItem(
                icon: Icons.description_outlined,
                title: 'Preventivi',
                isSelected: currentIndex == 5,
                onTap: () => _handleItemTap(context, 5),
              ),
              _DrawerItem(
                icon: Icons.more_horiz_outlined,
                title: 'Altro',
                isSelected: currentIndex == 6,
                onTap: () => _handleItemTap(context, 6),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54, size: 22),
            title: const Text('Esci', style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w500)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: onLogout,
            hoverColor: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        child: content,
      );
    }

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: content,
    );
  }

  void _handleItemTap(BuildContext context, int index) {
    onItemSelected(index);
    if (!isDesktop) {
      Navigator.pop(context); // Close the drawer on mobile
    }
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppThemeProvider>(context);
    final activeColor = theme.primaryColor;
    final defaultColor = Colors.white54;
    
    final color = widget.isSelected || _isHovering ? activeColor : defaultColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(right: BorderSide(color: activeColor, width: 3)),
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: color,
                size: 22,
                shadows: _isHovering || widget.isSelected
                    ? [Shadow(color: color, blurRadius: 10)]
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : (_isHovering ? Colors.white : Colors.white54),
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                  shadows: _isHovering || widget.isSelected
                      ? [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}