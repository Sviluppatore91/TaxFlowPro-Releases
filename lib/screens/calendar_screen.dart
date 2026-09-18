import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/security_utils.dart';
import 'package:intl/intl.dart';
import '../providers/app_theme_provider.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/daily_overview.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  final String role;
  const CalendarScreen({super.key, required this.role});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  Map<DateTime, List<Map<String, dynamic>>> _eventsMap = {};
  DateTime _selectedDate = DateTime.now();
  final DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _dbHelper.getCalendarEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredEvents = List.from(_events);
    } else {
      _filteredEvents = _events.where((e) {
        final title = (e['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Build events map
    _eventsMap = {};
    for (var event in _filteredEvents) {
      if (event['date'] != null) {
        try {
          final date = DateTime.parse(event['date']);
          final dayDate = DateTime(date.year, date.month, date.day);
          
          if (_eventsMap[dayDate] == null) {
            _eventsMap[dayDate] = [];
          }
          // Assign dummy color based on length for mockup
          event['color'] = _eventsMap[dayDate]!.length % 2 == 0 ? const Color(0xFF06B6D4) : const Color(0xFFE11D48);
          _eventsMap[dayDate]!.add(event);
        } catch (_) {}
      }
    }
  }

  Future<void> _showEventDialog([Map<String, dynamic>? event]) async {
    bool authorized = await SecurityUtils.requireAdminAuth(context);
    if (!authorized || !mounted) return;

    final isNew = event == null;
    final titleController = TextEditingController(text: isNew ? '' : event['title']);
    final dateController = TextEditingController(text: isNew ? '' : event['date']);
    bool isCompleted = isNew ? false : (event['is_completed'] == 1 || event['is_completed'] == true);
    bool isPaid = isNew ? false : (event['is_paid'] == 1 || event['is_paid'] == true);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: Text(isNew ? 'Nuovo Evento' : 'Modifica Evento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Titolo Evento'),
                  ),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Data (YYYY-MM-DD)'),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('yyyy-MM-dd').format(date);
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Completato'),
                    value: isCompleted,
                    onChanged: (val) => setStateBuilder(() => isCompleted = val ?? false),
                  ),
                  CheckboxListTile(
                    title: Text('Pagato'),
                    value: isPaid,
                    onChanged: (val) => setStateBuilder(() => isPaid = val ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annulla')),
                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'title': titleController.text,
                      'date': dateController.text,
                      'is_completed': isCompleted ? 1 : 0,
                      'is_paid': isPaid ? 1 : 0,
                    };
                    if (isNew) {
                      await _dbHelper.insertCalendarEvent(data);
                    } else {
                      data['id'] = event['id'];
                      await _dbHelper.updateCalendarEvent(data);
                    }
                    if (mounted) Navigator.pop(ctx);
                    _loadEvents();
                  },
                  child: Text('Salva'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEvent(String id) async {
    bool authorized = await SecurityUtils.requireAdminAuth(context);
    if (!authorized || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Conferma Elimina'),
        content: Text('Vuoi davvero eliminare questo evento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sì, Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteCalendarEvent(id);
      _loadEvents();
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> event, String field, bool value) async {
    bool authorized = await SecurityUtils.requireAdminAuth(context);
    if (!authorized || !mounted) return;

    final updated = Map<String, dynamic>.from(event);
    updated[field] = value ? 1 : 0;
    await _dbHelper.updateCalendarEvent(updated);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final monthStr = DateFormat('MMMM yyyy').format(_currentMonth);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TAX & ACCOUNTING | $monthStr',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: AssetImage('assets/images/avatar_mock.jpg'),
                            backgroundColor: Colors.grey,
                          ),
                          const SizedBox(width: -8),
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: AssetImage('assets/images/avatar_mock2.jpg'),
                            backgroundColor: Colors.blueGrey,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
                          const SizedBox(width: 12),
                          Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.5), size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Calendar Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CalendarGrid(
                    currentMonth: _currentMonth,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    events: _eventsMap,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Daily Overview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selected Date label Box
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            DateFormat('E, MMM dd').format(_selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Overview list
                        Expanded(
                          child: DailyOverview(
                            date: _selectedDate,
                            events: _eventsMap[DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)] ?? [],
                            onAddEvent: () => _showEventDialog(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}


