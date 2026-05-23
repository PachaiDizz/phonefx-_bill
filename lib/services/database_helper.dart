import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/repair_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('phonefx_plus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // bumped from 6 → 7
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN deviceBrand TEXT NOT NULL DEFAULT "Other"',
      );
      await db.execute('ALTER TABLE repairs ADD COLUMN pickupDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN warrantyVoidConditions TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN checklistBefore TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN checklistAfter TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN customerProvidedParts TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN repairNotes TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN billNumber TEXT',
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE repairs ADD COLUMN componentQualities TEXT NOT NULL DEFAULT ""',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE repairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        deviceType TEXT NOT NULL,
        deviceBrand TEXT NOT NULL,
        deviceModel TEXT NOT NULL,
        issues TEXT NOT NULL,
        customIssue TEXT,
        repairDate TEXT NOT NULL,
        pickupDate TEXT,
        warrantyPeriod TEXT NOT NULL,
        warrantyExpiryDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        createdAt TEXT NOT NULL,
        warrantyVoidConditions TEXT NOT NULL DEFAULT "",
        checklistBefore TEXT NOT NULL DEFAULT "",
        checklistAfter TEXT NOT NULL DEFAULT "",
        customerProvidedParts TEXT NOT NULL DEFAULT "",
        repairNotes TEXT,
        billNumber TEXT,
        componentQualities TEXT NOT NULL DEFAULT ""
      )
    ''');
  }

  Future<int> insertRepair(RepairRecord repair) async {
    final db = await database;
    return await db.insert('repairs', repair.toMap());
  }

  Future<List<RepairRecord>> getAllRepairs() async {
    final db = await database;
    final result = await db.query('repairs', orderBy: 'createdAt DESC');
    return result.map((map) => RepairRecord.fromMap(map)).toList();
  }

  Future<RepairRecord?> getRepair(int id) async {
    final db = await database;
    final result = await db.query('repairs', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return RepairRecord.fromMap(result.first);
  }

  Future<int> updateRepair(RepairRecord repair) async {
    final db = await database;
    return await db.update(
      'repairs',
      repair.toMap(),
      where: 'id = ?',
      whereArgs: [repair.id],
    );
  }

  Future<void> updateBillNumber(int id, String billNumber) async {
    final db = await database;
    await db.update(
      'repairs',
      {'billNumber': billNumber},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getRepairCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM repairs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteRepair(int id) async {
    final db = await database;
    return await db.delete('repairs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
