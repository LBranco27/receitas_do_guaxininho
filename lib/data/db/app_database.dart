import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase _i = AppDatabase._();
  factory AppDatabase() => _i;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'recipes.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            ingredients TEXT NOT NULL,
            steps TEXT NOT NULL,
            category TEXT NOT NULL,
            time_minutes INTEGER NOT NULL,
            servings INTEGER NOT NULL,
            image_path TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0
          );
        ''');
      },
    );
    return _db!;
  }
}
