import 'dart:io';

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

String _csvCell(String v) => '"${v.replaceAll('"', '""')}"';

/// Tableau CSV (séparateur « ; », lisible par Excel) de tous les contacts.
String contactsToCsv(List<Contact> contacts) {
  final rows = <List<String>>[
    [
      'Nom',
      'Poste',
      'Société',
      'Téléphone',
      'Email',
      'Site web',
      'Adresse',
      'Note',
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
  // BOM : Excel reconnaît ainsi l'UTF-8 (accents).
  return '﻿${rows.map((r) => r.map(_csvCell).join(';')).join('\r\n')}\r\n';
}

Future<void> shareContactsCsv(List<Contact> contacts) async {
  final file = await _tempFile('contacts-acg.csv', contactsToCsv(contacts));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Contacts ACG',
    ),
  );
}
