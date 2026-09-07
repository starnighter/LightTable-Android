import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

final class LightTableDatabase {
  LightTableDatabase({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;

  static const fileName = 'lighttable.db';
  static final shared = LightTableDatabase();

  final DatabaseFactory _factory;
  final String? databasePath;
  Database? _instance;
  Future<Database>? _opening;

  Future<Database> get database {
    final existing = _instance;
    if (existing != null && existing.isOpen) {
      return Future.value(existing);
    }
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    final resolvedPath =
        databasePath ?? path.join(await getDatabasesPath(), fileName);
    try {
      final database = await _factory.openDatabase(
        resolvedPath,
        options: OpenDatabaseOptions(
          version: DatabaseSchema.version,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
            if (resolvedPath != inMemoryDatabasePath) {
              await db.rawQuery('PRAGMA journal_mode = WAL');
            }
          },
          onCreate: (db, _) => DatabaseSchema.create(db),
          onUpgrade: DatabaseSchema.migrate,
        ),
      );
      _instance = database;
      return database;
    } finally {
      _opening = null;
    }
  }

  Future<void> close() async {
    final database = _instance ?? await _opening;
    _instance = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }
}
