import 'package:lighttable/data/database/light_table_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

LightTableDatabase createTestDatabase() {
  sqfliteFfiInit();
  return LightTableDatabase(
    factory: databaseFactoryFfi,
    databasePath: inMemoryDatabasePath,
  );
}
