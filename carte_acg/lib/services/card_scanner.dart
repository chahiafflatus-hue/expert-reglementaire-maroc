import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/contact.dart';
import 'card_parser.dart';

class ScanResult {
  const ScanResult(this.contact, this.rawText);
  final Contact contact;

  /// Texte brut lu sur la carte, affiché pour aider à corriger les champs.
  final String rawText;
}

/// Photographie (ou choisit) une carte de visite, lit son texte par OCR sur l'appareil
/// et renvoie un contact prérempli. Renvoie `null` si l'utilisateur annule.
Future<ScanResult?> scanBusinessCard(ImageSource source) async {
  final shot = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2400,
    imageQuality: 90,
  );
  if (shot == null) return null;

  // La photo est copiée dans le dossier de l'application pour rester liée au contact.
  final docs = await getApplicationDocumentsDirectory();
  final dir = await Directory(p.join(docs.path, 'cartes'))
      .create(recursive: true);
  final ext = p.extension(shot.path).isEmpty ? '.jpg' : p.extension(shot.path);
  final saved = p.join(
    dir.path,
    '${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  await File(shot.path).copy(saved);

  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(
      InputImage.fromFilePath(saved),
    );
    final text = [
      for (final block in result.blocks)
        for (final line in block.lines) line.text,
    ].join('\n');
    return ScanResult(parseBusinessCard(text).copyWith(imagePath: saved), text);
  } finally {
    await recognizer.close();
  }
}
