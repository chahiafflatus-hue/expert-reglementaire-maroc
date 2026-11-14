import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact.dart';

String _slug(String s) {
  final t = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return t.isEmpty ? 'contact' : t;
}

Future<File> _tempFile(String name, String content) async {
  final dir = await getTemporaryDirectory();
  return File(p.join(dir.path, name)).writeAsString(content);
}

/// Partage une fiche contact (.vcf) par WhatsApp, email, etc.
Future<void> shareVCard(String name, String vcard) async {
  final file = await _tempFile('${_slug(name)}.vcf', vcard);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/vcard')],
      subject: name,
    ),
  );
}

/// Classeur Excel (.xlsx) de tous les contacts : une ligne par carte enregistrée.
List<int> contactsToXlsx(List<Contact> contacts) {
  const sheet = 'Contacts';
  final book = xl.Excel.createExcel();
  book.rename(book.getDefaultSheet()!, sheet);
  final rows = <List<String>>[
    [
      'Nom',
      'Poste',
      'Société',
      'Téléphone',
      'Email',
      'Site web',
      'Adresse',
      'Note', //
      'Ajouté le',
    ],
    for (final c in contacts)
      [
        c.name,
        c.title,
        c.company,
        c.phone,
        c.email,
        c.website,
        c.address,
        c.note, //
        c.createdAt?.toIso8601String().substring(0, 10) ?? '',
      ],
  ];
  for (final row in rows) {
    // Tout est écrit en texte : Excel ne transforme pas les numéros de téléphone en nombres.
    book.appendRow(sheet, [for (final v in row) xl.TextCellValue(v)]);
  }
  const widths = [26.0, 24.0, 26.0, 18.0, 32.0, 26.0, 36.0, 36.0, 12.0];
  for (var i = 0; i < widths.length; i++) {
    book[sheet].setColumnWidth(i, widths[i]);
  }
  return book.encode()!;
}

Future<void> shareContactsXlsx(List<Contact> contacts) async {
  final dir = await getTemporaryDirectory();
  final file = await File(p.join(dir.path, 'contacts-acg.xlsx'))
      .writeAsBytes(contactsToXlsx(contacts));
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: 'Contacts ACG',
    ),
  );
}
