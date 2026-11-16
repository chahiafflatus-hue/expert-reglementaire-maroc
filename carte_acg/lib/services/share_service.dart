import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact.dart';
import '../models/share_entry.dart';

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

void _addSheet(
  xl.Excel book,
  String sheet,
  List<List<String>> rows,
  List<double> widths,
) {
  for (final row in rows) {
    // Tout est écrit en texte : Excel ne transforme pas les numéros de téléphone en nombres.
    book.appendRow(sheet, [for (final v in row) xl.TextCellValue(v)]);
  }
  for (var i = 0; i < widths.length; i++) {
    book[sheet].setColumnWidth(i, widths[i]);
  }
}

/// Classeur Excel (.xlsx) : une feuille « Contacts » (cartes enregistrées) et une feuille
/// « Historique » (partages de la carte notés par le consultant).
List<int> contactsToXlsx(
  List<Contact> contacts, {
  List<ShareEntry> history = const [],
}) {
  final book = xl.Excel.createExcel();
  book.rename(book.getDefaultSheet()!, 'Contacts');
  _addSheet(
    book,
    'Contacts',
    [
      [
        'Nom', 'Poste', 'Société', 'Téléphone', 'Email', 'Site web', //
        'Adresse', 'Note', 'Ajouté le',
      ],
      for (final c in contacts)
        [
          c.name, c.title, c.company, c.phone, c.email, c.website, //
          c.address, c.note,
          c.createdAt?.toIso8601String().substring(0, 10) ?? '',
        ],
    ],
    const [26, 24, 26, 18, 32, 26, 36, 36, 12],
  );
  _addSheet(
    book,
    'Historique',
    [
      ['Date', 'Type', 'Nom', 'Société', 'Téléphone', 'Email', 'Note'],
      for (final e in history)
        [
          e.dateLabel, e.kindLabel, e.name, e.company, e.phone, e.email, //
          e.note,
        ],
    ],
    const [18, 22, 26, 26, 18, 32, 40],
  );
  return book.encode()!;
}

Future<void> shareContactsXlsx(
  List<Contact> contacts, {
  List<ShareEntry> history = const [],
}) async {
  final dir = await getTemporaryDirectory();
  final file = await File(p.join(dir.path, 'contacts-acg.xlsx'))
      .writeAsBytes(contactsToXlsx(contacts, history: history));
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
