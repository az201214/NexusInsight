import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../database/app_database.dart';
import 'team_repository.dart';

class BackupRepository {
  BackupRepository(this._db, this._teamRepo);
  final AppDatabase _db;
  final TeamRepository _teamRepo;

  Future<String> exportBackup() async {
    final data = await _db.exportAll();
    final json = jsonEncode(data);
    final dir = await getApplicationDocumentsDirectory();
    final team = await _teamRepo.getTeam();
    final name = (team?.name ?? 'team').replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName =
        'krmaazha_${name}_${DateTime.now().millisecondsSinceEpoch}.${AppConstants.backupExtension}';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json);
    if (team != null) {
      final actor = await _teamRepo.getCurrentMember();
      await _teamRepo.logActivity(
        teamId: team.id,
        type: ActivityType.backupExported,
        message: 'Team backup exported',
        actorId: actor?.id,
      );
    }
    return file.path;
  }

  Future<void> shareBackup(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'Krmaazha Team Hub backup');
  }

  Future<void> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [AppConstants.backupExtension, 'json'],
    );
    if (result == null || result.files.single.path == null) return;
    final content = await File(result.files.single.path!).readAsString();
    await importFromJson(content);
  }

  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    await _db.replaceAllFromBackup(data);
    final team = await _teamRepo.getTeam();
    if (team != null) {
      await _teamRepo.logActivity(
        teamId: team.id,
        type: ActivityType.backupImported,
        message: 'Team data restored from backup',
      );
    }
  }
}
