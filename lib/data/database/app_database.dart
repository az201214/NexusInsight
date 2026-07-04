import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
          'shared_files',
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
    await db.execute('''
      CREATE TABLE shared_files (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size TEXT NOT NULL,
        file_type TEXT NOT NULL,
        uploaded_at INTEGER NOT NULL,
        uploaded_by TEXT NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tasks_team ON tasks(team_id, status)');
    await db.execute(
        'CREATE INDEX idx_meetings_team ON meetings(team_id, start_at)');
    await db.execute(
        'CREATE INDEX idx_activity_team ON activity_logs(team_id, created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_shared_files_team ON shared_files(team_id)');
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
        'shared_files',
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
      for (final row in (data['shared_files'] as List? ?? [])) {
        await txn.insert('shared_files', Map<String, dynamic>.from(row as Map));
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
      'shared_files': await db.query('shared_files'),
    };
  }
}

class MockDatabase implements Database, Transaction {
  static const _storage = FlutterSecureStorage();
  static Map<String, List<Map<String, dynamic>>>? _cachedDb;

  Future<Map<String, List<Map<String, dynamic>>>> _loadDb() async {
    if (_cachedDb != null) return _cachedDb!;
    
    final jsonStr = await _storage.read(key: 'mock_database_v2');
    if (jsonStr != null) {
      try {
        final rawMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final dbData = <String, List<Map<String, dynamic>>>{};
        rawMap.forEach((k, v) {
          if (v is List) {
            dbData[k] = v.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          }
        });
        _cachedDb = dbData;
        return dbData;
      } catch (e) {
        debugPrint('Error loading mock database: $e');
      }
    }
    
    // Seed initial mock data
    final initialDb = <String, List<Map<String, dynamic>>>{
      'teams': [
        {
          'id': 'web-team-id',
          'name': 'Web Client Team',
          'created_at': 1719878400000,
          'theme_mode': 'dark',
        }
      ],
      'members': [
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
      ],
      'app_settings': [
        {
          'team_id': 'web-team-id',
          'pin_hash': null,
          'lock_enabled': 0,
          'notifications_enabled': 1,
          'self_assign_only': 0,
          'onboarding_done': 1,
          'meeting_reminder_minutes': 15,
        }
      ],
      'meetings': [],
      'meeting_attendees': [],
      'tasks': [],
      'task_checklist': [],
      'task_comments': [],
      'activity_logs': [],
      'shared_files': [],
    };
    _cachedDb = initialDb;
    await _saveDb(initialDb);
    return initialDb;
  }

  Future<void> _saveDb(Map<String, List<Map<String, dynamic>>> dbData) async {
    _cachedDb = dbData;
    await _storage.write(key: 'mock_database_v2', value: jsonEncode(dbData));
  }

  bool _areEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is int && b is double) return a == b;
    if (a is double && b is int) return a == b;
    if (a is num && b is String) return a.toString() == b;
    if (a is String && b is num) return a == b.toString();
    return a?.toString() == b?.toString();
  }

  bool matchesCondition(Map<String, dynamic> row, String cond, List<dynamic> args, Map<String, int> argIdx) {
    cond = cond.trim();
    if (cond.isEmpty) return true;
    
    String? op;
    if (cond.contains('!=')) {
      op = '!=';
    } else if (cond.contains('>=')) {
      op = '>=';
    } else if (cond.contains('<')) {
      op = '<';
    } else if (cond.contains('=')) {
      op = '=';
    } else if (cond.contains('LIKE')) {
      op = 'LIKE';
    }
    
    if (op == null) return true;
    
    final parts = cond.split(op);
    final col = parts[0].trim();
    var valStr = parts[1].trim();
    
    dynamic targetVal;
    if (valStr == '?') {
      final idx = argIdx['idx']!;
      if (idx < args.length) {
        targetVal = args[idx];
        argIdx['idx'] = idx + 1;
      }
    } else {
      if (valStr.startsWith("'") && valStr.endsWith("'")) {
        targetVal = valStr.substring(1, valStr.length - 1);
      } else {
        targetVal = num.tryParse(valStr) ?? valStr;
      }
    }
    
    final rowVal = row[col];
    if (op == '=') {
      return _areEqual(rowVal, targetVal);
    } else if (op == '!=') {
      return !_areEqual(rowVal, targetVal);
    } else if (op == '>=') {
      if (rowVal is num && targetVal is num) {
        return rowVal >= targetVal;
      }
      return false;
    } else if (op == '<') {
      if (rowVal is num && targetVal is num) {
        return rowVal < targetVal;
      }
      return false;
    } else if (op == 'LIKE') {
      final rowStr = rowVal?.toString().toLowerCase() ?? '';
      final search = targetVal?.toString().replaceAll('%', '').toLowerCase() ?? '';
      return rowStr.contains(search);
    }
    return true;
  }

  bool matchesFilter(Map<String, dynamic> row, String? where, List<dynamic>? whereArgs) {
    if (where == null) return true;
    final args = whereArgs ?? [];
    var argIdx = {'idx': 0};
    
    String? parenthesized;
    var cleanWhere = where;
    final openParen = where.indexOf('(');
    final closeParen = where.indexOf(')');
    if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
      parenthesized = where.substring(openParen + 1, closeParen);
      cleanWhere = where.substring(0, openParen) + " __PAREN__ " + where.substring(closeParen + 1);
    }
    
    final parts = cleanWhere.split(' AND ');
    for (final part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isEmpty) continue;
      if (trimmedPart == '__PAREN__') {
        if (parenthesized != null) {
          final orParts = parenthesized.split(' OR ');
          bool orMatch = false;
          for (final orPart in orParts) {
            final matched = matchesCondition(row, orPart, args, argIdx);
            if (matched) {
              orMatch = true;
            }
          }
          if (!orMatch) return false;
        }
      } else {
        if (!matchesCondition(row, trimmedPart, args, argIdx)) {
          return false;
        }
      }
    }
    return true;
  }

  void sortRows(List<Map<String, dynamic>> rows, String? orderBy) {
    if (orderBy == null) return;
    final parts = orderBy.split(',');
    final sortSpecs = parts.map((p) {
      final clean = p.trim().split(RegExp(r'\s+'));
      final col = clean[0];
      final desc = clean.length > 1 && clean[1].toUpperCase() == 'DESC';
      return (column: col, desc: desc);
    }).toList();
    
    rows.sort((a, b) {
      for (final spec in sortSpecs) {
        final valA = a[spec.column];
        final valB = b[spec.column];
        if (valA == valB) continue;
        if (valA == null) return spec.desc ? 1 : -1;
        if (valB == null) return spec.desc ? -1 : 1;
        
        int cmp;
        if (valA is Comparable && valB is Comparable) {
          cmp = valA.compareTo(valB);
        } else {
          cmp = valA.toString().compareTo(valB.toString());
        }
        if (spec.desc) cmp = -cmp;
        return cmp;
      }
      return 0;
    });
  }

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
    final dbData = await _loadDb();
    final list = dbData[table] ?? [];
    
    // Filter
    var filtered = list.where((row) => matchesFilter(row, where, whereArgs)).toList();
    
    // Sort
    sortRows(filtered, orderBy);
    
    // Limit & Offset
    if (offset != null && offset < filtered.length) {
      filtered = filtered.sublist(offset);
    }
    if (limit != null && limit < filtered.length) {
      filtered = filtered.sublist(0, limit);
    }
    
    return filtered.map((e) => Map<String, Object?>.from(e)).toList();
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final dbData = await _loadDb();
    final list = dbData[table] ??= [];
    final newRow = Map<String, dynamic>.from(values);
    
    int? existingIdx;
    if (table == 'meeting_attendees') {
      final mId = newRow['meeting_id'];
      final memId = newRow['member_id'];
      existingIdx = list.indexWhere((r) => r['meeting_id'] == mId && r['member_id'] == memId);
    } else if (table == 'app_settings') {
      final teamId = newRow['team_id'];
      existingIdx = list.indexWhere((r) => r['team_id'] == teamId);
    } else {
      final id = newRow['id'];
      if (id != null) {
        existingIdx = list.indexWhere((r) => r['id'] == id);
      }
    }
    
    if (existingIdx != null && existingIdx != -1) {
      list[existingIdx] = newRow;
    } else {
      list.add(newRow);
    }
    
    await _saveDb(dbData);
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final dbData = await _loadDb();
    final list = dbData[table] ??= [];
    int count = 0;
    for (var i = 0; i < list.length; i++) {
      if (matchesFilter(list[i], where, whereArgs)) {
        final updatedRow = Map<String, dynamic>.from(list[i]);
        values.forEach((k, v) {
          updatedRow[k] = v;
        });
        list[i] = updatedRow;
        count++;
      }
    }
    if (count > 0) {
      await _saveDb(dbData);
    }
    return count;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final dbData = await _loadDb();
    final list = dbData[table] ??= [];
    final originalLength = list.length;
    list.removeWhere((row) => matchesFilter(row, where, whereArgs));
    final deletedCount = originalLength - list.length;
    if (deletedCount > 0) {
      await _saveDb(dbData);
    }
    return deletedCount;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    return action(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future<void>.value();
    }
    if (invocation.memberName == #execute) {
      return Future<void>.value();
    }
    return null;
  }
}
