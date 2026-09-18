import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'providers/app_theme_provider.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup ffi for Windows/Linux desktop apps for local DB if still needed
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // DUMMY DATA INIT
    final dbHelper = DatabaseHelper();
    
    // Add test user if not present
    try {
      final users = await dbHelper.getUsers();
      bool hasTestUser = users.any((u) => u['username'] == 'sviluppoapk@gmail.com' || u['email'] == 'sviluppoapk@gmail.com');
      if (!hasTestUser) {
        await dbHelper.insertUser({
          'username': 'sviluppoapk@gmail.com',
          'email': 'sviluppoapk@gmail.com',
          'password_hash': 'admin123',
          'role': 'admin'
        });
      }
    } catch (e) {
      debugPrint('Warning: Could not seed test user: $e');
    }

    final customers = await dbHelper.getCustomers();
    if (customers.isEmpty) {
      String c1 = await dbHelper.insertCustomer({
        'name': 'Tech Corp SPA',
        'email': 'admin@techcorp.it',
        'phone': '02 1234567',
        'address': 'Via Roma 1, Milano',
        'vat_number': '01234567890',
        'fiscal_code': 'TCHCRP80A01F205W',
        'notes': 'Cliente VIP'
      });
      String c2 = await dbHelper.insertCustomer({
        'name': 'Mario Rossi Srl',
        'email': 'mario@rossisrl.it',
        'phone': '333 1234567',
        'address': 'Via Garibaldi 10, Torino',
        'vat_number': '09876543210',
        'fiscal_code': 'MRORSS70A01H501U',
        'notes': 'Pagamento a 60gg'
      });
      
      await dbHelper.insertInvoice({
        'customer_id': c1,
        'amount': 2500.0,
        'date': DateTime.now().toIso8601String(),
        'status': 'Pagata'
      });
      
      await dbHelper.insertInvoice({
        'customer_id': c2,
        'amount': 1500.0,
        'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'status': 'In Attesa'
      });
      
      await dbHelper.insertDeadline({
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'description': 'Scadenza F24 Tech Corp'
      });
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => AppThemeProvider(),
        child: const ContabileApp(),
      ),
    );
  } catch (e, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Startup Error:\n$e\n\nStack:\n$stack',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
  }
}

class ContabileApp extends StatelessWidget {
  const ContabileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Bimbomixer',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: themeProvider.scaffoldBackgroundColor,
            colorScheme: ColorScheme.dark(
              primary: themeProvider.primaryColor,
              secondary: themeProvider.secondaryColor,
              surface: themeProvider.cardColor,
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
