import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../widgets/glass_container.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ServiceType> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshServices();
  }

  Future<void> _refreshServices() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getServiceTypes();
    setState(() {
      _services = data.map((e) => ServiceType.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  void _showServiceDialog([ServiceType? service]) {
    final nameController = TextEditingController(text: service?.name);
    
    // Default color if none is set
    Color selectedColor = service?.colorHex != null 
        ? Color(int.parse(service!.colorHex!)) 
        : Colors.grey;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  service == null ? 'Nuovo Servizio' : 'Modifica Servizio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome Servizio *',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7))),
                  ),
                ),
                SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateSB) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Colore (per grafico)', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.deepPurpleAccent,
                            Colors.indigoAccent, Colors.blueAccent, Colors.lightBlueAccent, Colors.cyanAccent,
                            Colors.tealAccent, Colors.greenAccent, Colors.lightGreenAccent, Colors.limeAccent,
                            Colors.yellowAccent, Colors.amberAccent, Colors.orangeAccent, Colors.deepOrangeAccent,
                            Colors.grey
                          ].map((c) => GestureDetector(
                            onTap: () => setStateSB(() => selectedColor = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor.toARGB32() == c.toARGB32() ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    );
                  }
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('ANNULLA', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final newService = ServiceType(
                          id: service?.id,
                          name: nameController.text.trim(),
                          colorHex: selectedColor.toARGB32().toString(),
                        );

                        if (service == null) {
                          await _dbHelper.insertServiceType(newService.toMap());
                        } else {
                          await _dbHelper.updateServiceType(newService.toMap());
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _refreshServices();
                      },
                      child: Text('SALVA'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteService(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conferma Eliminazione', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Eliminando questo servizio, i pagamenti associati rimarranno senza servizio. Procedere?', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('ANNULLA', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('ELIMINA'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteServiceType(id);
      _refreshServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'SERVICES & PRODUCTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Services', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Container(height: 3, color: Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Products', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                        SizedBox(height: 8),
                        Container(height: 3, color: Colors.white.withValues(alpha: 0.1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
                  : _services.isEmpty
                      ? Center(child: Text('Nessun servizio definito.', style: TextStyle(color: Colors.white.withValues(alpha: 0.54))))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final srv = _services[index];
                            return ServiceCard(
                              service: srv.toMap(),
                              onTap: () {},
                              onEdit: () => _showServiceDialog(srv),
                              onDelete: () => _deleteService(srv.id!),
                            );
                          },
                        ),
            ),
            
            // Add custom service button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () => _showServiceDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ).copyWith(
                  elevation: ButtonStyleButton.allOrNull(0.0),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)
                    ],
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'ADD CUSTOM SERVICE',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

