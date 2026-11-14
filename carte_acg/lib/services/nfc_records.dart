import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

/// Enregistrement NDEF « lien web » : lu par les iPhone comme par les Android.
NdefRecord uriRecord(String url) {
  // Octet de préfixe de la spécification NFC Forum URI : 0x04 = "https://", 0x00 = aucun.
  final https = url.startsWith('https://');
  return NdefRecord(
    typeNameFormat: TypeNameFormat.wellKnown,
    type: Uint8List.fromList([0x55]), // "U"
    identifier: Uint8List(0),
    payload: Uint8List.fromList([
      https ? 0x04 : 0x00,
      ...utf8.encode(https ? url.substring(8) : url),
    ]),
  );
}

/// Enregistrement NDEF « fiche contact » : Android propose directement d'ajouter le contact,
/// sans internet. Les iPhone ne lisent pas ce type d'enregistrement en arrière-plan.
NdefRecord vcardRecord(String vcard) => NdefRecord(
  typeNameFormat: TypeNameFormat.media,
  type: Uint8List.fromList(ascii.encode('text/vcard')),
  identifier: Uint8List(0),
  payload: Uint8List.fromList(utf8.encode(vcard)),
);
