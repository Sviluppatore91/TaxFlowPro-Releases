import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import 'dashboard_screen.dart';
import 'payments_screen.dart';
import 'invoices_screen.dart';
import 'deadlines_selection_screen.dart';
import 'menu_screen.dart';
import 'notes_screen.dart';
import 'quotes_screen.dart';
import 'login_screen.dart';
import '../widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  final String role;
  final String username;
  
  const MainScreen({super.key, required this.role, this.username = ''});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastActivity;

  // Timeout sessione: 30 minuti di inattività
  static const int _sessionTimeoutMinutes = 30;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActivity = DateTime.now();
    _screens = [
      DashboardScreen(role: widget.role),
      const PaymentsScreen(),
      const InvoicesScreen(),
      const DeadlinesSelectionScreen(),
      const NotesScreen(),
      const QuotesScreen(),
      MenuScreen(role: widget.role),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    } else if (state == AppLifecycleState.paused) {
      _lastActivity = DateTime.now();
    }
  }

  void _checkSessionTimeout() {
    if (_lastActivity != null) {
      final elapsed = DateTime.now().difference(_lastActivity!);
      if (elapsed.inMinutes >= _sessionTimeoutMinutes) {
        _logout(reason: 'Sessione scaduta per inattività.');
      }
    }
    _lastActivity = DateTime.now();
  }

  Future<void> _logout({String? reason}) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Non bloccare il logout
    }
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      if (reason != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnessione'),
        content: Text('Sei sicuro di voler uscire dall\'app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULLA'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('ESCI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reset activity timer on any interaction
    _lastActivity = DateTime.now();
    final theme = Provider.of<AppThemeProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 850;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: AppDrawer(
                    currentIndex: _currentIndex,
                    onItemSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    onLogout: _showLogoutConfirmation,
                    isDesktop: true,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar Area
                      _buildTopBar(context),
                      // Main Content
                      Expanded(
                        child: _screens[_currentIndex],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('TaxFlow PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: _screens[_currentIndex],
          drawer: AppDrawer(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() => _currentIndex = index);
            },
            onLogout: _showLogoutConfirmation,
            isDesktop: false,
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Provider.of<AppThemeProvider>(context, listen: false);
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.primaryColor,
                child: Text(
                  widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username.isNotEmpty ? widget.username : 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(widget.role, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
