import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/contact.dart';

/// Base de données locale (SQLite) des cartes de visite reçues.
class ContactsDb {
  ContactsDb._();
  static final instance = ContactsDb._();

  Database? _db;

  Future<Database> get _database async {
    return _db ??= await openDatabase(
      p.join(await getDatabasesPath(), 'contacts.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE contacts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL DEFAULT '',
          title TEXT NOT NULL DEFAULT '',
          company TEXT NOT NULL DEFAULT '',
          phone TEXT NOT NULL DEFAULT '',
          email TEXT NOT NULL DEFAULT '',
          website TEXT NOT NULL DEFAULT '',
          address TEXT NOT NULL DEFAULT '',
          note TEXT NOT NULL DEFAULT '',
          image_path TEXT,
          created_at INTEGER NOT NULL
        )'''),
    );
  }

  /// Tous les contacts, ou ceux qui contiennent [query] dans un de leurs champs.
  Future<List<Contact>> list({String query = ''}) async {
    final db = await _database;
    final q = query.trim();
    final rows = await db.query(
      'contacts',
      where: q.isEmpty
          ? null
          : Contact.columns.map((c) => '$c LIKE ?').join(' OR '),
      whereArgs: q.isEmpty ? null : List.filled(Contact.columns.length, '%$q%'),
      orderBy: 'created_at DESC',
    );
    return rows.map(Contact.fromMap).toList();
  }

  Future<Contact> save(Contact c) async {
    final db = await _database;
    if (c.id == null) {
      final id = await db.insert('contacts', c.toMap());
      return c.copyWith(id: id);
    }
    final map = c.toMap()..remove('created_at');
    await db.update('contacts', map, where: 'id = ?', whereArgs: [c.id]);
    return c;
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
