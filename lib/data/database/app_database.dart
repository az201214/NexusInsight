import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (kIsWeb) {
      return MockDatabase();
    }
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      return MockDatabase();
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        final tables = [
          'meeting_attendees',
          'meetings',
          'task_comments',
          'task_checklist',
          'tasks',
          'activity_logs',
          'members',
          'app_settings',
          'teams',
        ];
        for (final t in tables) {
          await db.execute('DROP TABLE IF EXISTS $t');
        }
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        theme_mode TEXT NOT NULL DEFAULT 'system'
      )
    ''');
    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        avatar_color INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        joined_at INTEGER NOT NULL,
        is_current_user INTEGER NOT NULL DEFAULT 0,
        email TEXT,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        assignee_id TEXT,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        due_at INTEGER,
        created_by TEXT NOT NULL,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE task_checklist (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE task_comments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE meetings (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        title TEXT NOT NULL,
        start_at INTEGER NOT NULL,
        end_at INTEGER NOT NULL,
        location TEXT,
        notes TEXT,
        agenda TEXT,
        created_by TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE meeting_attendees (
        meeting_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        PRIMARY KEY (meeting_id, member_id),
        FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        type TEXT NOT NULL,
        reference_id TEXT,
        message TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        actor_id TEXT,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        team_id TEXT PRIMARY KEY,
        pin_hash TEXT,
        lock_enabled INTEGER NOT NULL DEFAULT 0,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        self_assign_only INTEGER NOT NULL DEFAULT 0,
        onboarding_done INTEGER NOT NULL DEFAULT 0,
        meeting_reminder_minutes INTEGER NOT NULL DEFAULT 15,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tasks_team ON tasks(team_id, status)');
    await db.execute(
        'CREATE INDEX idx_meetings_team ON meetings(team_id, start_at)');
    await db.execute(
        'CREATE INDEX idx_activity_team ON activity_logs(team_id, created_at DESC)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> replaceAllFromBackup(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'meeting_attendees',
        'meetings',
        'task_comments',
        'task_checklist',
        'tasks',
        'activity_logs',
        'members',
        'app_settings',
        'teams',
      ]) {
        await txn.delete(table);
      }
      for (final row in (data['teams'] as List? ?? [])) {
        await txn.insert('teams', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['members'] as List? ?? [])) {
        await txn.insert('members', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['app_settings'] as List? ?? [])) {
        await txn.insert('app_settings', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['tasks'] as List? ?? [])) {
        await txn.insert('tasks', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['task_checklist'] as List? ?? [])) {
        await txn.insert('task_checklist', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['task_comments'] as List? ?? [])) {
        await txn.insert('task_comments', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['meetings'] as List? ?? [])) {
        await txn.insert('meetings', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['meeting_attendees'] as List? ?? [])) {
        await txn.insert(
            'meeting_attendees', Map<String, dynamic>.from(row as Map));
      }
      for (final row in (data['activity_logs'] as List? ?? [])) {
        await txn.insert('activity_logs', Map<String, dynamic>.from(row as Map));
      }
    });
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'teams': await db.query('teams'),
      'members': await db.query('members'),
      'app_settings': await db.query('app_settings'),
      'tasks': await db.query('tasks'),
      'task_checklist': await db.query('task_checklist'),
      'task_comments': await db.query('task_comments'),
      'meetings': await db.query('meetings'),
      'meeting_attendees': await db.query('meeting_attendees'),
      'activity_logs': await db.query('activity_logs'),
    };
  }
}

class MockDatabase implements Database {
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == 'teams') {
      return [
        {
          'id': 'web-team-id',
          'name': 'Web Client Team',
          'created_at': 1719878400000,
          'theme_mode': 'dark',
        }
      ];
    } else if (table == 'members') {
      return [
        {
          'id': 'web-client-id',
          'team_id': 'web-team-id',
          'name': 'Web Admin',
          'role': 'head',
          'avatar_color': 4283215696, // 0xFF4CAF50
          'is_active': 1,
          'joined_at': 1719878400000,
          'is_current_user': 1,
        }
      ];
    } else if (table == 'app_settings') {
      return [
        {
          'team_id': 'web-team-id',
          'pin_hash': null,
          'lock_enabled': 0,
          'notifications_enabled': 1,
          'self_assign_only': 0,
          'onboarding_done': 1,
          'meeting_reminder_minutes': 15,
        }
      ];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future<void>.value();
    }
    if (invocation.memberName == #execute) {
      return Future<void>.value();
    }
    if (invocation.memberName == #insert) {
      return Future<int>.value(1);
    }
    if (invocation.memberName == #update) {
      return Future<int>.value(1);
    }
    if (invocation.memberName == #delete) {
      return Future<int>.value(0);
    }
    if (invocation.memberName == #transaction) {
      final dynamic callback = invocation.positionalArguments.first;
      return callback(this);
    }
    return null;
  }
}

