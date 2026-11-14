import 'dart:convert';

import 'package:carte_acg/models/card_data.dart';
import 'package:carte_acg/models/contact.dart';
import 'package:carte_acg/models/vcard.dart';
import 'package:carte_acg/services/card_parser.dart';
import 'package:carte_acg/services/nfc_records.dart';
import 'package:carte_acg/services/share_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = CardData(
    prenom: 'Abdellah',
    nom: 'CHAHI',
    titre: 'Head of Consulting',
    tel: '+212 695 519 600',
    email: 'chahi.abdellah@afflatusconsulting.com',
  );

  group('ma carte', () {
    test('la vCard contient le contact, le site et le lien de besoin', () {
      final v = card.toVCard();
      expect(v, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
      expect(v, contains('N:CHAHI;Abdellah;;;'));
      expect(v, contains('TEL;TYPE=CELL:+212695519600'));
      expect(
        v,
        contains('EMAIL;TYPE=WORK:chahi.abdellah@afflatusconsulting.com'),
      );
      expect(v, contains('URL:https://afflatus.consulting'));
      expect(v, contains('item1.URL:https://inspirra.tech/p/opportunite/'));
      expect(v, endsWith('END:VCARD\r\n'));
    });

    test('le lien web se décode comme dans la page web', () {
      final data = card.webLink.split('#c=').last;
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(data))),
      );
      expect(CardData.fromJson(json)!.nomComplet, 'Abdellah CHAHI');
      expect(data, isNot(contains('=')));
    });

    test('aller-retour JSON, y compris le badge BRCGS', () {
      const c = CardData(
        prenom: 'Ismail',
        nom: 'IDRISSI',
        titre: 'Founder & CEO',
        tel: '+212 600 611 353',
        email: 'a@b.ma',
        brcgs: true,
      );
      final back = CardData.fromJson(jsonDecode(jsonEncode(c.toJson())))!;
      expect(back.brcgs, isTrue);
      expect(back.titre, 'Founder & CEO');
      expect(CardData.fromJson({'p': 'x'}), isNull);
    });

    test('les caractères spéciaux sont échappés dans la vCard', () {
      final v = buildVCard(fullName: 'Dupont; Jean', org: 'A, B & Co');
      expect(v, contains(r'FN:Dupont\; Jean'));
      expect(v, contains(r'ORG:A\, B & Co'));
    });
  });

  group('NFC', () {
    test('le lien est encodé avec le préfixe https', () {
      final r = uriRecord('https://example.com/a#c=xyz');
      expect(r.payload.first, 0x04);
      expect(utf8.decode(r.payload.sublist(1)), 'example.com/a#c=xyz');
    });

    test('la fiche contact est un enregistrement text/vcard', () {
      final r = vcardRecord(card.toVCard());
      expect(ascii.decode(r.type), 'text/vcard');
      expect(utf8.decode(r.payload), card.toVCard());
    });
  });

  group('lecture OCR d\'une carte', () {
    test('carte ACG', () {
      final c = parseBusinessCard('''
Afflatus
Consulting
Group
Kaoutar BOUGOUFFA
HEAD OF TRAINING
+212 699 226 003
kaoutar.bougouffa@afflatusconsulting.com
contact@afflatusconsulting.com
AFFLATUS.CONSULTING
RABAT · KÉNITRA · MAROC
''');
      expect(c.name, 'Kaoutar BOUGOUFFA');
      expect(c.title, 'HEAD OF TRAINING');
      expect(c.phone, '+212 699 226 003');
      expect(c.email, 'kaoutar.bougouffa@afflatusconsulting.com');
      expect(c.website, 'AFFLATUS.CONSULTING');
      expect(c.address, contains('RABAT'));
      expect(c.note, contains('contact@afflatusconsulting.com'));
    });

    test('carte française avec fixe, mobile, adresse et société', () {
      final c = parseBusinessCard('''
ATLAS FOOD INDUSTRIES S.A.
Youssef El Amrani
Directeur Qualité
Tél : 05 22 34 56 78   GSM : 06 61 23 45 67
y.elamrani@atlasfood.ma
www.atlasfood.ma
Lot 12, Zone Industrielle Ain Sebaa, Casablanca
''');
      expect(c.name, 'Youssef El Amrani');
      expect(c.title, 'Directeur Qualité');
      expect(c.company, 'ATLAS FOOD INDUSTRIES S.A.');
      expect(c.phone, '06 61 23 45 67');
      expect(c.note, contains('05 22 34 56 78'));
      expect(c.email, 'y.elamrani@atlasfood.ma');
      expect(c.website, 'www.atlasfood.ma');
      expect(c.address, contains('Zone Industrielle'));
    });

    test('société déduite du domaine quand elle n\'est pas reconnue', () {
      final c = parseBusinessCard(
        'Sara Benali\nsara@nutrimar.ma\n+212661000000',
      );
      expect(c.name, 'Sara Benali');
      expect(c.company, 'Nutrimar');
    });

    test('texte vide', () {
      final c = parseBusinessCard('');
      expect(c.name, isEmpty);
      expect(c.phone, isEmpty);
    });
  });

  test('export Excel : en-tête et contacts relus depuis le fichier', () {
    final bytes = contactsToXlsx([
      const Contact(
        name: 'Youssef El Amrani',
        company: 'Atlas Food',
        phone: '+212661234567',
      ),
      const Contact(name: 'Sara Benali', email: 'sara@nutrimar.ma'),
    ]);
    final sheet = Excel.decodeBytes(bytes)['Contacts'];
    String cell(int r, int c) => sheet.rows[r][c]?.value.toString() ?? '';
    expect(sheet.maxRows, 3);
    expect(cell(0, 0), 'Nom');
    expect(cell(0, 3), 'Téléphone');
    expect(cell(1, 0), 'Youssef El Amrani');
    expect(cell(1, 3), '+212661234567');
    expect(cell(2, 4), 'sara@nutrimar.ma');
  });
}
