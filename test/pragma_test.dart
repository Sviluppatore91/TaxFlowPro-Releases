import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('pragma test', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE service_types (id TEXT)');
    final result = await db.rawQuery("PRAGMA table_info(service_types)");
    print("Result: \$result");
    await db.close();
  });
}
