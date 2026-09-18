import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class CloudMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> syncFromCloud() async {
    final db = await _dbHelper.database;
    final collections = [
      'users',
      'customers',
      'categories',
      'service_types',
      'payments',
      'invoices',
      'deadlines',
      'calendar_events',
      'memo_events',
      'scheduled_payments',
      'quotes',
      'notes',
    ];

    for (String collection in collections) {
      try {
        // Get valid column names for this table
        final tableInfo = await db.rawQuery("PRAGMA table_info($collection)");
        final validColumns = tableInfo.map((c) => c['name'] as String).toSet();

        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          
          final safeData = _sanitizeDataForSqlite(data);
          
          // Filter out keys that don't exist as columns in the SQLite table
          final filteredData = Map<String, dynamic>.fromEntries(
            safeData.entries.where((e) => validColumns.contains(e.key)),
          );

          if (filteredData.isEmpty) continue;
          
          final columns = filteredData.keys.join(', ');
          final placeholders = List.filled(filteredData.length, '?').join(', ');
          final values = filteredData.values.toList();
          
          try {
            await db.execute(
              'INSERT OR REPLACE INTO $collection ($columns) VALUES ($placeholders)',
              values,
            );
          } catch (e) {
            debugPrint('Error inserting into $collection (doc ${doc.id}): $e');
          }
        }
        debugPrint('Synced $collection: ${snapshot.docs.length} items');
      } catch (e) {
        debugPrint('Error syncing $collection: $e');
      }
    }
  }

  Map<String, dynamic> _sanitizeDataForSqlite(Map<String, dynamic> data) {
    Map<String, dynamic> safeData = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        safeData[key] = value.toDate().toIso8601String();
      } else if (value is bool) {
        safeData[key] = value ? 1 : 0;
      } else if (value is Map || value is List) {
        safeData[key] = jsonEncode(value);
      } else {
        safeData[key] = value;
      }
    });
    return safeData;
  }
}
