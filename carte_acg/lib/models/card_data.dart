import 'dart:convert';

import '../config.dart';
import 'vcard.dart';

/// La carte de visite du consultant (stockée sur son téléphone, modifiable à tout moment).
class CardData {
  const CardData({
    required this.prenom,
    required this.nom,
    required this.titre,
    required this.tel,
    required this.email,
    this.brcgs = false,
  });

  final String prenom;
  final String nom;
  final String titre;
  final String tel;
  final String email;

  /// Affiche le logo « BRCGS Approved Consultant ».
  final bool brcgs;

  String get nomComplet => '$prenom $nom'.trim();

  /// Clés courtes : le même format est lu par la page web (`docs/app.js`).
  Map<String, dynamic> toJson() => {
    'p': prenom,
    'n': nom,
    't': titre,
    'm': tel,
    'e': email,
    if (brcgs) 'b': 1,
  };

  static CardData? fromJson(Object? json) {
    if (json is! Map) return null;
    String f(String k) => json[k] is String ? (json[k] as String).trim() : '';
    final c = CardData(
      prenom: f('p'),
      nom: f('n'),
      titre: f('t'),
      tel: f('m'),
      email: f('e'),
      brcgs: json['b'] == 1 || json['b'] == true,
    );
    return c.prenom.isEmpty || c.nom.isEmpty ? null : c;
  }

  /// Fiche contact encodée dans le QR code : le scan enregistre le contact, avec le site
  /// et le lien d'expression de besoin cliquables depuis la fiche.
  String toVCard() => buildVCard(
    given: prenom,
    family: nom,
    org: kOrg,
    title: titre,
    phones: [tel],
    emails: [email, kContactEmail],
    website: kSite,
    extraUrl: kBesoinUrl,
    extraUrlLabel: kBesoinLabel,
    city: kVille,
    country: kPays,
  );

  /// Lien vers la page web de la carte (pour les puces NFC et le partage par lien).
  String get webLink {
    final data = base64Url
        .encode(utf8.encode(jsonEncode(toJson())))
        .replaceAll('=', '');
    return '$kWebCardBase#c=$data';
  }
}
