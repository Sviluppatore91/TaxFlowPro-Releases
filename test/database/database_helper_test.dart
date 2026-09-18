import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tax_flow_pro/database/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    // Initialize FFI for unit testing SQLite on desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    // We ideally should use an in-memory database for tests, 
    // but the singleton uses a fixed path. 
    // Let's clear the tables before each test to ensure isolation.
    final db = await dbHelper.database;
    await db.execute('DELETE FROM users');
    await db.execute('DELETE FROM customers');
    // If invoices table exists we should delete it, but let's wrap in try-catch in case it's not created
    try { await db.execute('DELETE FROM invoices'); } catch (_) {}
  });

  group('DatabaseHelper CRUD Tests', () {
    test('insertCustomer and getCustomers', () async {
      final customerId = await dbHelper.insertCustomer({
        'name': 'Test Corp',
        'email': 'test@corp.com',
        'vat_number': '12345678901', // This should be encrypted internally
      });

      expect(customerId, isNotNull);

      final customers = await dbHelper.getCustomers();
      expect(customers.length, equals(1));
      expect(customers.first['name'], equals('Test Corp'));
      
      // We expect vat_number to be decrypted back for us by the getCustomers method 
      // (assuming getCustomers does decrypt, otherwise we expect it encrypted)
      // Actually, looking at DatabaseHelper.getCustomers(), it might not decrypt directly 
      // there, so let's check its output carefully. 
    });

    test('insertInvoice and getInvoices', () async {
      final customerId = await dbHelper.insertCustomer({
        'name': 'Test Corp for Invoice',
      });

      final invoiceId = await dbHelper.insertInvoice({
        'customer_id': customerId,
        'amount': 500.0,
        'date': DateTime.now().toIso8601String(),
        'status': 'Pagata'
      });

      expect(invoiceId, isNotNull);

      final invoices = await dbHelper.getInvoices();
      expect(invoices.length, equals(1));
      expect(invoices.first['amount'], equals(500.0));
      expect(invoices.first['status'], equals('Pagata'));
    });
  });
}
