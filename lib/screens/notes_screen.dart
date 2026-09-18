import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import '../database/database_helper.dart';
import 'note_form_screen.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _dbHelper.getNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote(String id) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Elimina nota', style: TextStyle(color: Colors.white)),
        content: Text('Sei sicuro di voler eliminare questa nota?', style: TextStyle(color: Colors.white.withValues(alpha: 0.70))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annulla', style: TextStyle(color: Colors.white.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteNote(id);
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer();
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Note Generali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Text(
                    'APPUNTI',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Search and Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', true, theme),
                            SizedBox(width: 8),
                            _buildFilterChip('Expenses', false, theme),
                            SizedBox(width: 8),
                            _buildFilterChip('Income', false, theme),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Grid of notes
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Text('Nessuna nota presente.', style: TextStyle(color: Colors.white.withValues(alpha: 0.54))),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : (MediaQuery.of(context).size.width > 500 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final colors = [
                              const Color(0xFFE11D48), // Pink
                              const Color(0xFF06B6D4), // Cyan
                              Theme.of(context).colorScheme.primary, // Purple
                            ];
                            
                            return NoteCard(
                              note: note,
                              glowColor: colors[index % colors.length],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteFormScreen(note: note),
                                  ),
                                );
                                _loadNotes();
                              },
                              onDelete: () => _deleteNote(note['id']),
                            );
                          },
                        ),
                ),
                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBottomButton(Icons.add, 'Add Note', const Color(0xFFE11D48), () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NoteFormScreen(),
                          ),
                        );
                        _loadNotes();
                      }),
                      SizedBox(width: 16),
                      _buildBottomButton(Icons.upload, 'Export Data', const Color(0xFF06B6D4), () {}),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, AppThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
          color: color.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
