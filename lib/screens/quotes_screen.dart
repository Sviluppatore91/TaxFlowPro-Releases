import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_theme_provider.dart';
import '../database/database_helper.dart';
import '../services/attachment_service.dart';
import '../widgets/quote_table_row.dart';
import '../widgets/glass_container.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AttachmentService _attachmentService = AttachmentService();
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final q = await _dbHelper.getQuotes();
      if (mounted) {
        setState(() {
          _quotes = q;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento preventivi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadQuote() async {
    try {
      File? file = await _attachmentService.pickFile(context);
      if (file == null) return;

      setState(() => _isLoading = true);

      // Upload file
      String? url = await _attachmentService.uploadAttachment(file, 'quotes');
      if (url == null) {
        throw Exception("Upload fallito");
      }

      // Compute next serial number
      int nextSerial = 1;
      if (_quotes.isNotEmpty) {
        for (var q in _quotes) {
          int s = int.tryParse(q['serial_number']?.toString() ?? '0') ?? 0;
          if (s >= nextSerial) {
            nextSerial = s + 1;
          }
        }
      }

      await _dbHelper.insertQuote({
        'serial_number': nextSerial,
        'file_name': p.basename(file.path),
        'file_url': url,
        'accepted': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadQuotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preventivo caricato con successo!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editSerialNumber(Map<String, dynamic> quote) async {
    final tc = TextEditingController(text: quote['serial_number']?.toString() ?? '');

    final newSerialStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Modifica Seriale', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: tc,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Numero Seriale',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.54)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Annulla', style: TextStyle(color: Colors.white.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, tc.text),
            child: Text('Salva', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );

    if (newSerialStr != null && newSerialStr.isNotEmpty) {
      final newSerial = int.tryParse(newSerialStr);
      if (newSerial != null) {
        await _dbHelper.updateQuote({'id': quote['id'], 'serial_number': newSerial});
        _loadQuotes();
      }
    }
  }

  Future<void> _updateQuoteState(Map<String, dynamic> quote, {required bool accepted, required bool rejected}) async {
    await _dbHelper.updateQuote({'id': quote['id'], 'accepted': accepted, 'rejected': rejected});
    _loadQuotes();
  }

  Future<void> _deleteQuote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('Elimina', style: TextStyle(color: Colors.white)),
        content: Text('Eliminare questo preventivo?', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annulla', style: TextStyle(color: Colors.white.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Elimina', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteQuote(id);
      _loadQuotes();
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire il file.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer();
            },
          ),
        ),
        title: Text('Preventivi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadQuote,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.upload_file, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Riepilogo Preventivi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40), // For checkbox
                          Expanded(flex: 2, child: Text('ID Preventivo', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                          Expanded(flex: 3, child: Text('Nome File', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                          Expanded(flex: 2, child: Text('Data', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                          Expanded(flex: 2, child: Text('Stato', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                          Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Text('Azioni', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)))),
                        ],
                      ),
                    ),
                    // Table Rows
                    Expanded(
                      child: _quotes.isEmpty
                          ? Center(
                              child: Text('Nessun preventivo presente.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                            )
                          : ListView.builder(
                              itemCount: _quotes.length,
                              itemBuilder: (context, index) {
                                final quote = _quotes[index];
                                final isAccepted = quote['accepted'] == true;

                                return QuoteTableRow(
                                  quote: quote,
                                  isSelected: isAccepted,
                                  onTap: () => _editSerialNumber(quote),
                                  onDownload: () => _openFile(quote['file_url'] ?? ''),
                                  onDelete: () => _deleteQuote(quote['id']),
                                  onAccept: () => _updateQuoteState(quote, accepted: true, rejected: false),
                                  onReject: () => _updateQuoteState(quote, accepted: false, rejected: true),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}



