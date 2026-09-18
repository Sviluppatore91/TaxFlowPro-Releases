import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/password_hasher.dart';
import '../utils/crypto_utils.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  String? currentUser;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static String? testDatabasePath;

  /// Restituisce il percorso del file locale
  static Future<String> getDatabasePath() async {
    if (testDatabasePath != null) return testDatabasePath!;
    final directory = await getApplicationDocumentsDirectory();
    final contabileAppDir = p.join(directory.path, 'contabile_app');
    return p.join(contabileAppDir, 'contabile.db');
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    final info = await db.rawQuery("PRAGMA table_info($table)");
    final existingColumns = info.map((c) => c['name'] as String).toSet();
    if (!existingColumns.contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'users', 'email', 'TEXT');
      await _addColumnIfNotExists(db, 'users', 'phone', 'TEXT');
    }
    if (oldVersion < 3) {
      // customers
      await _addColumnIfNotExists(db, 'customers', 'sdi_code', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'tax_code', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'address_street', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'address_zip', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'address_city', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'address_province', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'pec', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'contacts', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'cig', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'cup', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'pa_reference', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'pa_contract', 'TEXT');
      await _addColumnIfNotExists(db, 'customers', 'logo_path', 'TEXT');
      
      // categories
      await _addColumnIfNotExists(db, 'categories', 'type', 'TEXT');
      await _addColumnIfNotExists(db, 'categories', 'color_hex', 'TEXT');
      
      // service_types
      await _addColumnIfNotExists(db, 'service_types', 'color_hex', 'TEXT');
      
      // payments
      await _addColumnIfNotExists(db, 'payments', 'type', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'category_id', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'attachments', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'status', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'event_dates', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'date_to', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'title', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'client_phone', 'TEXT');
      await _addColumnIfNotExists(db, 'payments', 'client_email', 'TEXT');
      
      // invoices
      await _addColumnIfNotExists(db, 'invoices', 'number', 'TEXT');
      await _addColumnIfNotExists(db, 'invoices', 'notes', 'TEXT');
      await _addColumnIfNotExists(db, 'invoices', 'event_date', 'TEXT');
      await _addColumnIfNotExists(db, 'invoices', 'vat_code', 'TEXT');
      
      // deadlines
      await _addColumnIfNotExists(db, 'deadlines', 'amount', 'REAL');
      await _addColumnIfNotExists(db, 'deadlines', 'title', 'TEXT');
      await _addColumnIfNotExists(db, 'deadlines', 'category_id', 'TEXT');
      await _addColumnIfNotExists(db, 'deadlines', 'status', 'TEXT');
    }
  }
  
  /// Chiude e ricrea il database (usato dopo il ripristino da Drive)
  Future<void> reloadDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE users (id TEXT PRIMARY KEY, username TEXT, email TEXT, role TEXT, password_hash TEXT, phone TEXT)''');
    await db.execute('''CREATE TABLE login_attempts (id TEXT PRIMARY KEY, username TEXT, timestamp TEXT, type TEXT)''');
    await db.execute('''CREATE TABLE customers (id TEXT PRIMARY KEY, name TEXT, email TEXT, phone TEXT, address TEXT, vat_number TEXT, fiscal_code TEXT, notes TEXT, sdi_code TEXT, tax_code TEXT, address_street TEXT, address_zip TEXT, address_city TEXT, address_province TEXT, pec TEXT, contacts TEXT, cig TEXT, cup TEXT, pa_reference TEXT, pa_contract TEXT, logo_path TEXT)''');
    await db.execute('''CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, type TEXT, color_hex TEXT)''');
    await db.execute('''CREATE TABLE service_types (id TEXT PRIMARY KEY, name TEXT, category_id TEXT, price REAL, color_hex TEXT)''');
    await db.execute('''CREATE TABLE payments (id TEXT PRIMARY KEY, customer_id TEXT, service_id TEXT, amount REAL, date TEXT, payment_method TEXT, notes TEXT, is_recurring INTEGER, recurrence_type TEXT, type TEXT, category_id TEXT, attachments TEXT, status TEXT, event_dates TEXT, date_to TEXT, title TEXT, client_phone TEXT, client_email TEXT)''');
    await db.execute('''CREATE TABLE invoices (id TEXT PRIMARY KEY, customer_id TEXT, amount REAL, date TEXT, status TEXT, number TEXT, notes TEXT, event_date TEXT, vat_code TEXT)''');
    await db.execute('''CREATE TABLE deadlines (id TEXT PRIMARY KEY, date TEXT, description TEXT, amount REAL, title TEXT, category_id TEXT, status TEXT)''');
    await db.execute('''CREATE TABLE access_logs (id TEXT PRIMARY KEY, username TEXT, role TEXT, device_type TEXT, timestamp TEXT, event_type TEXT)''');
    await db.execute('''CREATE TABLE audit_log (id TEXT PRIMARY KEY, username TEXT, event_type TEXT, severity TEXT, description TEXT, target_id TEXT, target_collection TEXT, timestamp TEXT)''');
    await db.execute('''CREATE TABLE calendar_events (id TEXT PRIMARY KEY, date TEXT, title TEXT, description TEXT)''');
    await db.execute('''CREATE TABLE memo_events (id TEXT PRIMARY KEY, date TEXT, event_date TEXT, memo TEXT)''');
    await db.execute('''CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT, content TEXT, creation_date TEXT, update_date TEXT)''');
    await db.execute('''CREATE TABLE scheduled_payments (id TEXT PRIMARY KEY, customer_id TEXT, amount REAL, date TEXT, status TEXT)''');
    await db.execute('''CREATE TABLE quotes (id TEXT PRIMARY KEY, serial_number TEXT, customer_id TEXT, amount REAL, date TEXT, status TEXT)''');
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + (DateTime.now().microsecondsSinceEpoch % 1000).toString();
  }

  // --- CRUD USERS ---
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<String> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    final data = Map<String, dynamic>.from(user);
    final id = _generateId();
    data['id'] = id;
    if (data['password_hash'] != null && !PasswordHasher.isHashed(data['password_hash'])) {
      data['password_hash'] = PasswordHasher.hashPassword(data['password_hash']);
    }
    await db.insert('users', data);
    
    if (currentUser != null) {
      await logAuditEvent(
        username: currentUser!,
        eventType: 'CREATE',
        severity: 'HIGH',
        description: 'Creazione nuovo utente: ${data['username']}',
        targetCollection: 'users',
        targetId: id,
      );
    }
    return id;
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    final id = user['id'];
    final data = Map<String, dynamic>.from(user);
    if (data['password_hash'] != null && !PasswordHasher.isHashed(data['password_hash'])) {
      data['password_hash'] = PasswordHasher.hashPassword(data['password_hash']);
    }
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);

    if (currentUser != null) {
      await logAuditEvent(
        username: currentUser!,
        eventType: 'UPDATE',
        severity: 'HIGH',
        description: 'Modifica utente: ${data['username'] ?? id}',
        targetCollection: 'users',
        targetId: id,
      );
    }
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    if (currentUser != null) {
      await logAuditEvent(
        username: currentUser!,
        eventType: 'DELETE',
        severity: 'CRITICAL',
        description: 'Eliminazione utente',
        targetCollection: 'users',
        targetId: id,
      );
    }
  }

  Future<Map<String, dynamic>?> verifyCredentials(String username, String password) async {
    final users = await getUsers();
    for (var user in users) {
      if (user['username'] == username) {
        final storedHash = user['password_hash']?.toString() ?? user['password']?.toString() ?? '';
        if (PasswordHasher.verifyPassword(password, storedHash)) {
          if (!PasswordHasher.isHashed(storedHash)) {
            try {
              final updateData = Map<String, dynamic>.from(user);
              updateData['password_hash'] = PasswordHasher.hashPassword(password);
              await updateUser(updateData);
            } catch (e) {}
          }
          return user;
        }
        
        // Se la password normale fallisce ma è Bimbomixer/Bimbomixer, forza il reset
        if (username == 'Bimbomixer' && password == 'Bimbomixer') {
          try {
            final updateData = Map<String, dynamic>.from(user);
            updateData['password_hash'] = PasswordHasher.hashPassword(password);
            await updateUser(updateData);
            return updateData;
          } catch (e) {}
        }
        return null;
      }
    }
    
    // Se l'utente non esiste e le credenziali sono Bimbomixer/Bimbomixer, crealo
    if (username == 'Bimbomixer' && password == 'Bimbomixer') {
      try {
        final newId = await insertUser({
          'username': 'Bimbomixer',
          'role': 'Admin',
          'password_hash': PasswordHasher.hashPassword('Bimbomixer'),
        });
        return {
          'id': newId,
          'username': 'Bimbomixer',
          'role': 'Admin',
        };
      } catch (e) {
        print("Errore creazione utente Bimbomixer: $e");
      }
    }
    return null;
  }

  Future<bool> verifyAdminPassword(String password) async {
    final users = await getUsers();
    for (var user in users) {
      if (user['role']?.toString().toLowerCase() == 'admin') {
        final storedHash = user['password_hash']?.toString() ?? user['password']?.toString() ?? '';
        if (PasswordHasher.verifyPassword(password, storedHash)) {
          if (!PasswordHasher.isHashed(storedHash)) {
            try {
               final updateData = Map<String, dynamic>.from(user);
               updateData['password_hash'] = PasswordHasher.hashPassword(password);
               await updateUser(updateData);
            } catch (e) {}
          }
          return true;
        }
      }
    }
    return false;
  }

  // --- RATE LIMITING ---
  Future<int> recordFailedLogin(String username) async {
    final db = await database;
    await db.insert('login_attempts', {
      'id': _generateId(),
      'username': username,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'failed',
    });
    return await getRecentFailedAttempts(username);
  }

  Future<int> getRecentFailedAttempts(String username, {int minutes = 5}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes)).toIso8601String();
    final result = await db.query('login_attempts', 
        where: 'username = ? AND type = ? AND timestamp > ?', 
        whereArgs: [username, 'failed', cutoff]);
    return result.length;
  }

  Future<void> cleanOldLoginAttempts() async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
    await db.delete('login_attempts', where: 'timestamp < ?', whereArgs: [cutoff]);
  }

  // --- CRUD CUSTOMERS ---
  Future<String> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    final data = Map<String, dynamic>.from(customer);
    final id = _generateId();
    data['id'] = id;
    if (data['vat_number'] != null) data['vat_number'] = CryptoUtils.encryptData(data['vat_number']);
    if (data['fiscal_code'] != null) data['fiscal_code'] = CryptoUtils.encryptData(data['fiscal_code']);
    await db.insert('customers', data);
    return id;
  }

  Future<void> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    final id = customer['id'];
    final data = Map<String, dynamic>.from(customer);
    if (data['vat_number'] != null) data['vat_number'] = CryptoUtils.encryptData(data['vat_number']);
    if (data['fiscal_code'] != null) data['fiscal_code'] = CryptoUtils.encryptData(data['fiscal_code']);
    await db.update('customers', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((data) {
      var mutData = Map<String, dynamic>.from(data);
      if (mutData['vat_number'] != null) mutData['vat_number'] = CryptoUtils.decryptData(mutData['vat_number']);
      if (mutData['fiscal_code'] != null) mutData['fiscal_code'] = CryptoUtils.decryptData(mutData['fiscal_code']);
      return mutData;
    }).toList();
  }

  // --- CRUD CATEGORIES ---
  Future<String> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    final data = Map<String, dynamic>.from(category);
    final id = _generateId();
    data['id'] = id;
    await db.insert('categories', data);
    return id;
  }

  Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    final id = category['id'];
    await db.update('categories', category, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  // --- CRUD SERVICE TYPES ---
  Future<String> insertServiceType(Map<String, dynamic> service) async {
    final db = await database;
    final data = Map<String, dynamic>.from(service);
    final id = _generateId();
    data['id'] = id;
    await db.insert('service_types', data);
    return id;
  }

  Future<void> updateServiceType(Map<String, dynamic> service) async {
    final db = await database;
    final id = service['id'];
    await db.update('service_types', service, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteServiceType(String id) async {
    final db = await database;
    await db.delete('service_types', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getServiceTypes() async {
    final db = await database;
    return await db.query('service_types', orderBy: 'name ASC');
  }

  // --- CRUD PAYMENTS ---
  Future<String> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    final data = Map<String, dynamic>.from(payment);
    final id = _generateId();
    data['id'] = id;
    await db.insert('payments', data);
    return id;
  }

  Future<void> updatePayment(Map<String, dynamic> payment) async {
    final db = await database;
    final id = payment['id'];
    await db.update('payments', payment, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    if (currentUser != null) {
      await logAuditEvent(
        username: currentUser!,
        eventType: 'DELETE',
        severity: 'CRITICAL',
        description: 'Eliminazione pagamento',
        targetCollection: 'payments',
        targetId: id,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPayments({int? year, String? startDate, String? endDate}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (startDate != null && endDate != null) {
      maps = await db.query('payments', where: 'date >= ? AND date <= ?', whereArgs: [startDate, endDate]);
    } else if (year != null) {
      String start = "$year-01-01";
      String end = "${year + 1}-01-01";
      maps = await db.query('payments', where: 'date >= ? AND date < ?', whereArgs: [start, end]);
    } else {
      maps = await db.query('payments');
    }
    
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      String dateA = a['date'] ?? '';
      String dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });

    try {
      final customers = await getCustomers();
      final services = await getServiceTypes();
      final Map<String, String> customerNames = { for (var c in customers) c['id']: (c['name'] ?? '').toString() };
      final Map<String, String> serviceNames = { for (var s in services) s['id']: (s['name'] ?? '').toString() };
      
      for (var doc in docs) {
        final cid = doc['customer_id']?.toString() ?? '';
        final sid = doc['service_id']?.toString() ?? '';
        doc['customer_name'] = cid.isNotEmpty ? (customerNames[cid] ?? '') : '';
        doc['service_name'] = sid.isNotEmpty ? (serviceNames[sid] ?? '') : '';
      }
    } catch (_) {}

    return docs;
  }

  Future<List<Map<String, dynamic>>> getPaymentsByCustomer(String customerId) async {
    final db = await database;
    final maps = await db.query('payments', where: 'customer_id = ?', whereArgs: [customerId]);
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      String dateA = a['date'] ?? '';
      String dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return docs;
  }

  Future<Map<String, dynamic>?> getPaymentById(String id) async {
    final db = await database;
    final maps = await db.query('payments', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Map<String, dynamic>.from(maps.first);
    return null;
  }

  // --- CRUD INVOICES ---
  Future<String> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    final data = Map<String, dynamic>.from(invoice);
    final id = _generateId();
    data['id'] = id;
    await db.insert('invoices', data);
    return id;
  }

  Future<void> updateInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    final id = invoice['id'];
    await db.update('invoices', invoice, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteInvoice(String id) async {
    final db = await database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
    if (currentUser != null) {
      await logAuditEvent(
        username: currentUser!,
        eventType: 'DELETE',
        severity: 'CRITICAL',
        description: 'Eliminazione fattura',
        targetCollection: 'invoices',
        targetId: id,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    final maps = await db.query('invoices', orderBy: 'date DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // --- CRUD DEADLINES ---
  Future<String> insertDeadline(Map<String, dynamic> deadline) async {
    final db = await database;
    final data = Map<String, dynamic>.from(deadline);
    final id = _generateId();
    data['id'] = id;
    await db.insert('deadlines', data);
    return id;
  }

  Future<void> updateDeadline(Map<String, dynamic> deadline) async {
    final db = await database;
    final id = deadline['id'];
    await db.update('deadlines', deadline, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDeadline(String id) async {
    final db = await database;
    await db.delete('deadlines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDeadlines() async {
    final db = await database;
    final maps = await db.query('deadlines', orderBy: 'date ASC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // --- ACCESS LOGS ---
  Future<void> logAccess(String username, String role, String deviceType, {String eventType = 'login_success'}) async {
    final db = await database;
    final id = _generateId();
    await db.insert('access_logs', {
      'id': id,
      'username': username,
      'role': role,
      'device_type': deviceType,
      'timestamp': DateTime.now().toIso8601String(),
      'event_type': eventType,
    });
  }

  Future<List<Map<String, dynamic>>> getAccessLogs() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final maps = await db.query('access_logs', where: 'timestamp > ?', whereArgs: [sevenDaysAgo], orderBy: 'timestamp DESC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // --- AUDIT LOG ---
  Future<void> logAuditEvent({
    required String username,
    required String eventType,
    required String severity,
    required String description,
    String? targetId,
    String? targetCollection,
  }) async {
    final db = await database;
    await db.insert('audit_log', {
      'id': _generateId(),
      'username': username,
      'event_type': eventType,
      'severity': severity,
      'description': description,
      'target_id': targetId,
      'target_collection': targetCollection,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 100}) async {
    final db = await database;
    final maps = await db.query('audit_log', orderBy: 'timestamp DESC', limit: limit);
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // --- CRUD CALENDAR EVENTS ---
  Future<String> insertCalendarEvent(Map<String, dynamic> event) async {
    final db = await database;
    final data = Map<String, dynamic>.from(event);
    final id = _generateId();
    data['id'] = id;
    await db.insert('calendar_events', data);
    return id;
  }

  Future<void> updateCalendarEvent(Map<String, dynamic> event) async {
    final db = await database;
    final id = event['id'];
    await db.update('calendar_events', event, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCalendarEvent(String id) async {
    final db = await database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    final db = await database;
    final maps = await db.query('calendar_events', orderBy: 'date ASC');
    return maps.map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // --- CRUD MEMO EVENTS ---
  Future<String> insertMemoEvent(Map<String, dynamic> memo) async {
    final db = await database;
    final data = Map<String, dynamic>.from(memo);
    final id = _generateId();
    data['id'] = id;
    await db.insert('memo_events', data);
    return id;
  }

  Future<void> updateMemoEvent(Map<String, dynamic> memo) async {
    final db = await database;
    final id = memo['id'];
    await db.update('memo_events', memo, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMemoEvent(String id) async {
    final db = await database;
    await db.delete('memo_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getMemoEvents() async {
    final db = await database;
    final maps = await db.query('memo_events');
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      String dateA = a['event_date'] ?? a['date'] ?? '';
      String dateB = b['event_date'] ?? b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return docs;
  }

  // --- CRUD NOTE ---
  Future<String> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    final data = Map<String, dynamic>.from(note);
    final id = _generateId();
    data['id'] = id;
    await db.insert('notes', data);
    return id;
  }

  Future<void> updateNote(Map<String, dynamic> note) async {
    final db = await database;
    final id = note['id'];
    await db.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes');
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      String dateA = a['update_date'] ?? a['creation_date'] ?? '';
      String dateB = b['update_date'] ?? b['creation_date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return docs;
  }

  // --- CRUD SCHEDULED PAYMENTS ---
  Future<String> insertScheduledPayment(Map<String, dynamic> payment) async {
    final db = await database;
    final data = Map<String, dynamic>.from(payment);
    final id = _generateId();
    data['id'] = id;
    await db.insert('scheduled_payments', data);
    return id;
  }

  Future<void> updateScheduledPayment(Map<String, dynamic> payment) async {
    final db = await database;
    final id = payment['id'];
    await db.update('scheduled_payments', payment, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteScheduledPayment(String id) async {
    final db = await database;
    await db.delete('scheduled_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getScheduledPaymentById(String id) async {
    final db = await database;
    final maps = await db.query('scheduled_payments', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Map<String, dynamic>.from(maps.first);
    return null;
  }

  Future<List<Map<String, dynamic>>> getScheduledPayments() async {
    final db = await database;
    final maps = await db.query('scheduled_payments');
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      String dateA = a['date'] ?? '';
      String dateB = b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
    return docs;
  }

  // --- CRUD QUOTES ---
  Future<String> insertQuote(Map<String, dynamic> quote) async {
    final db = await database;
    final data = Map<String, dynamic>.from(quote);
    if (data['serial_number'] == null) {
       final allQuotes = await getQuotes();
       int maxSerial = 0;
       for (var q in allQuotes) {
         final s = q['serial_number'];
         if (s != null) {
           final sInt = int.tryParse(s.toString());
           if (sInt != null && sInt > maxSerial) {
             maxSerial = sInt;
           }
         }
       }
       data['serial_number'] = (maxSerial + 1).toString();
    }
    final id = _generateId();
    data['id'] = id;
    await db.insert('quotes', data);
    return id;
  }

  Future<void> updateQuote(Map<String, dynamic> quote) async {
    final db = await database;
    final id = quote['id'];
    await db.update('quotes', quote, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteQuote(String id) async {
    final db = await database;
    await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getQuotes() async {
    final db = await database;
    final maps = await db.query('quotes');
    var docs = maps.map((m) => Map<String, dynamic>.from(m)).toList();
    docs.sort((a, b) {
      final sA = int.tryParse(a['serial_number']?.toString() ?? '0') ?? 0;
      final sB = int.tryParse(b['serial_number']?.toString() ?? '0') ?? 0;
      return sB.compareTo(sA);
    });
    return docs;
  }
}
