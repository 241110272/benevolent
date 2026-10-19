import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Android/iOS use a transactional SQLite document. Browser preview uses prefs.
/// User records and public feed cache are stored separately.
class AppPersistence {
  AppPersistence(this.preferences, {this.database, this.initialState});
  final SharedPreferences preferences;
  final Database? database;
  final String? initialState;
  static const stateKey = 'langkahkerja.v2';

  static Future<AppPersistence> open(SharedPreferences prefs) async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return AppPersistence(prefs, initialState: prefs.getString(stateKey));
    }
    final path = await getDatabasesPath();
    final db = await openDatabase(
      '$path/langkahkerja.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE documents (id TEXT PRIMARY KEY, payload TEXT NOT NULL)',
        );
      },
    );
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: ['user'],
    );
    return AppPersistence(
      prefs,
      database: db,
      initialState: rows.isEmpty
          ? prefs.getString(stateKey)
          : rows.first['payload'] as String,
    );
  }

  Future<void> write(String value) async {
    if (database case final db?) {
      await db.transaction((txn) async {
        final old = await txn.query(
          'documents',
          where: 'id = ?',
          whereArgs: ['user'],
        );
        if (old.isNotEmpty) {
          await txn.insert('documents', {
            'id': 'previous',
            'payload': old.first['payload'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await txn.insert('documents', {
          'id': 'user',
          'payload': value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } else if (!await preferences.setString(stateKey, value)) {
      throw StateError('Penyimpanan tidak berhasil');
    }
  }

  Future<void> clear() async {
    if (database case final db?) await db.delete('documents');
    await preferences.remove(stateKey);
    await preferences.remove('langkahkerja.v1');
    await preferences.remove('langkahkerja.recovery');
  }
}
