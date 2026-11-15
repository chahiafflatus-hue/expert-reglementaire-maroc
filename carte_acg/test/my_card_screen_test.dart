import 'dart:convert';
import 'dart:io';

import 'package:carte_acg/models/card_data.dart';
import 'package:carte_acg/screens/my_card_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Montserrat');
  for (final f in ['Medium', 'MediumItalic', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Montserrat-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorSchemeSeed: const Color(0xFF8F3247),
      ),
      home: const Scaffold(body: MyCardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('premier lancement : invite à créer la carte', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, const Size(360, 640));
    expect(find.text('Créer ma carte'), findsOneWidget);
  });

  // Le nom le plus long de l'équipe sur un petit écran : rien ne doit déborder.
  testWidgets('carte enregistrée : affichée sans débordement sur petit écran', (
    tester,
  ) async {
    const card = CardData(
      prenom: 'Mohammed',
      nom: 'ELBOUKHARI',
      titre: 'Business Analyst',
      tel: '+212 614 617 985',
      email: 'mohammed.elboukhari@afflatus.ma',
      email2: 'mohammed.elboukhari@gmail.com',
      brcgs: true,
      qualifications: ['brcgs', 'ifs', 'fssc', 'irca'],
    );
    SharedPreferences.setMockInitialValues({
      'acg-carte-v1': jsonEncode(card.toJson()),
    });
    await _pump(tester, const Size(360, 640));
    expect(find.text('Mohammed ELBOUKHARI'), findsOneWidget);
    expect(find.text('BUSINESS ANALYST'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Sur un écran de taille courante, les boutons sont visibles sans défilement.
    await _pump(tester, const Size(390, 760));
    expect(tester.getBottomLeft(find.text('Modifier')).dy, lessThan(760 - 40));
    expect(tester.takeException(), isNull);

    // « Besoin » remplace le QR du contact par celui du formulaire, « Contact » y revient.
    expect(find.textContaining('ENREGISTRER'), findsOneWidget);
    await tester.tap(find.text('Besoin'));
    await tester.pumpAndSettle();
    expect(find.textContaining('EXPRIMER'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.environment['CARTE_SCREENSHOT'] != null) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Platform.environment['CARTE_SCREENSHOT']!),
      );
    }
  });
}
