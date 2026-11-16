import 'package:carte_acg/models/contact.dart';
import 'package:carte_acg/models/share_entry.dart';
import 'package:carte_acg/services/contacts_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Reproduit un téléphone qui a déjà la base de la première version (contacts seuls) :
  // la mise à jour doit ajouter l'historique sans toucher aux contacts.
  test(
    'mise à jour de la base v1 : contacts conservés, historique utilisable',
    () async {
      final path = p.join(await getDatabasesPath(), 'contacts.db');
      await deleteDatabase(path);
      final v1 = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) => db.execute('''
        CREATE TABLE contacts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL DEFAULT '', title TEXT NOT NULL DEFAULT '',
          company TEXT NOT NULL DEFAULT '', phone TEXT NOT NULL DEFAULT '',
          email TEXT NOT NULL DEFAULT '', website TEXT NOT NULL DEFAULT '',
          address TEXT NOT NULL DEFAULT '', note TEXT NOT NULL DEFAULT '',
          image_path TEXT, created_at INTEGER NOT NULL
        )'''),
      );
      await v1.insert(
        'contacts',
        const Contact(name: 'Ancien contact').toMap(),
      );
      await v1.close();

      final db = ContactsDb.instance;
      expect((await db.list()).single.name, 'Ancien contact');

      var changes = 0;
      db.historyChanges.addListener(() => changes++);
      await db.saveHistory(
        const ShareEntry(kind: ShareEntry.kindBesoin, name: 'Nadia'),
      );
      await db.saveHistory(const ShareEntry(name: 'Karim', company: 'Atlas'));
      final history = await db.history();
      expect(history.map((e) => e.name).toSet(), {'Nadia', 'Karim'});
      expect(
        history.firstWhere((e) => e.name == 'Nadia').kindLabel,
        'Expression de besoin',
      );

      await db.deleteHistory(history.first.id!);
      expect(await db.history(), hasLength(1));
      expect(changes, 3);

      await db.save(const Contact(name: 'Nouveau', company: 'ACG'));
      expect(await db.list(query: 'acg'), hasLength(1));
      expect(await db.list(), hasLength(2));
    },
  );
}
