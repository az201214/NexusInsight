import '../database/app_database.dart';
import '../models/shared_file.dart';

class SharedFileRepository {
  SharedFileRepository(this._db);
  final AppDatabase _db;

  Future<List<SharedFile>> getFiles(String teamId) async {
    final db = await _db.database;
    final r = await db.query(
      'shared_files',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'uploaded_at DESC',
    );
    return r.map(SharedFile.fromMap).toList();
  }

  Future<void> addFile(SharedFile file) async {
    final db = await _db.database;
    await db.insert('shared_files', file.toMap());
  }

  Future<void> deleteFile(String id) async {
    final db = await _db.database;
    await db.delete('shared_files', where: 'id = ?', whereArgs: [id]);
  }
}
