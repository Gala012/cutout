import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_cutout_burst_entity.dart';
class CutoutBurstDb extends GetxService {
  static CutoutBurstDb get to => Get.find();
  static const String _dbName = 'cutout_burst.db';
  static const int _dbVersion = 1;
  static const String _tableCutoutHistory = 'cutout_history';
  Database? _db;
  Future<CutoutBurstDb> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return this;
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableCutoutHistory (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        result_path    TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        cutout_mode    TEXT NOT NULL,
        created_at     TEXT NOT NULL
      )
    ''');
  }
  Future<List<CutoutHistory>> getCutoutHistories() async {
    try {
      final maps = await _db!.query(
        _tableCutoutHistory,
        orderBy: 'created_at DESC, id DESC',
      );
      return maps.map(CutoutHistory.fromMap).toList();
    } catch (e) {
      return [];
    }
  }
  Future<List<CutoutHistory>> getRecentCutoutHistories(int limit) async {
    try {
      final maps = await _db!.query(
        _tableCutoutHistory,
        orderBy: 'created_at DESC, id DESC',
        limit: limit,
      );
      return maps.map(CutoutHistory.fromMap).toList();
    } catch (e) {
      return [];
    }
  }
  Future<int> insertCutoutHistory(CutoutHistory history) async {
    try {
      return await _db!.insert(
        _tableCutoutHistory,
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      return -1;
    }
  }
  Future<int> deleteCutoutHistory(int id) async {
    try {
      return await _db!.delete(
        _tableCutoutHistory,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return 0;
    }
  }
  Future<int> deleteCutoutHistories(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final placeholders = List.filled(ids.length, '?').join(', ');
      return await _db!.delete(
        _tableCutoutHistory,
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e) {
      return 0;
    }
  }
}
