import '../models/contact.dart';

/// Transforme le texte lu par l'OCR sur une carte de visite en champs de contact.
///
/// L'OCR renvoie des lignes sans dire laquelle est le nom ou la société : on les classe
/// avec des règles simples (email, téléphone, site, mots-clés de poste / société / adresse).
/// Le résultat est toujours présenté à l'utilisateur pour correction avant enregistrement.
Contact parseBusinessCard(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.length > 1)
      .toList();

  final emails = <String>[];
  final phones = <String>[];
  final sites = <String>[];
  final address = <String>[];
  final rest = <String>[];

  for (final line in lines) {
    var consumed = false;

    final lineEmails = _email.allMatches(line).map((m) => m[0]!).toList();
    if (lineEmails.isNotEmpty) {
      emails.addAll(lineEmails);
      consumed = true;
    }

    final withoutEmails = line.replaceAll(_email, ' ');
    for (final m in _site.allMatches(withoutEmails)) {
      sites.add(m[0]!);
      consumed = true;
    }

    if (_addressWords.hasMatch(line)) {
      address.add(line);
      continue;
    }

    for (final m in _phone.allMatches(withoutEmails)) {
      final digits = m[0]!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 9 && digits.length <= 15) {
        phones.add(m[0]!.trim());
        consumed = true;
      }
    }

    if (!consumed) rest.add(line);
  }

  // Poste : première ligne contenant un mot-clé de fonction.
  final title = _firstWhere(rest, _titleWords.hasMatch);
  if (title != null) rest.remove(title);

  // Société : ligne avec une forme juridique / mot-clé, sinon déduite du domaine de l'email.
  var company = _firstWhere(rest, _companyWords.hasMatch);
  if (company != null) rest.remove(company);

  // Nom : ligne de 2 à 4 mots alphabétiques ; priorité à celle qui ressemble à l'email.
  final email = emails.isEmpty ? '' : _pickPersonalEmail(emails);
  final local = email.split('@').first.toLowerCase();
  final candidates = rest.where(_looksLikeName).toList();
  String? name;
  if (local.isNotEmpty) {
    name = _firstWhere(candidates, (l) {
      return l
          .toLowerCase()
          .split(' ')
          .any((w) => w.length > 2 && local.contains(_plain(w)));
    });
  }
  name ??= candidates.isEmpty ? null : candidates.first;
  if (name != null) rest.remove(name);

  if (company == null && email.isNotEmpty) {
    final domain = email.split('@').last.toLowerCase();
    final label = domain.split('.').first;
    if (!_publicMail.contains(label) && label.isNotEmpty) {
      // Une ligne restante qui reprend le nom de domaine est très probablement la société.
      company = _firstWhere(
        rest,
        (l) => _plain(l).contains(label) || label.contains(_plain(l)),
      );
      if (company != null) {
        rest.remove(company);
      } else {
        company = label[0].toUpperCase() + label.substring(1);
      }
    }
  }

  phones.sort((a, b) => _mobileRank(a).compareTo(_mobileRank(b)));
  final otherPhones = phones.skip(1);
  final otherEmails = emails.where((e) => e != email);

  return Contact(
    name: name ?? '',
    title: title ?? '',
    company: company ?? '',
    phone: phones.isEmpty ? '' : phones.first,
    email: email,
    website: sites.isEmpty ? '' : sites.first,
    address: address.join(', '),
    note: [...otherPhones, ...otherEmails, ...rest].join('\n'),
  );
}

final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
final _site = RegExp(
  r'(?:https?://|www\.)[^\s,;]+|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|ma|fr|net|org|io|co|eu|tech|consulting|info|biz|africa)\b(?:/[^\s,;]*)?',
  caseSensitive: false,
);
final _phone = RegExp(r'(?:\+|00)?\d[\d\s.\-()]{7,}\d');

final _titleWords = RegExp(
  r'\b(directeur|directrice|director|manager|responsable|ing[ée]nieur|engineer|consultant|consultante|chef|ceo|cto|cfo|coo|founder|fondateur|fondatrice|g[ée]rant|g[ée]rante|head|lead|analyst|analyste|commercial|commerciale|pr[ée]sident|pr[ée]sidente|officer|technicien|technicienne|qualit[ée]|assistant|assistante|charg[ée]e? |coordinateur|coordinatrice|auditeur|auditrice|expert|sales|marketing|achats|acheteur|acheteuse|pdg|dg|drh|qhse|hse|rh|product owner|d[ée]veloppeur|developer|designer|architecte|avocat|docteur|professeur|formateur|formatrice)\b',
  caseSensitive: false,
);
final _companyWords = RegExp(
  r'\b(sarl|s\.a\.r\.l|s\.a\.?|sas|sa|ltd|inc|llc|gmbh|group|groupe|consulting|soci[ée]t[ée]|company|compagnie|industries?|holding|corporation|corp|[ée]tablissements?|ets|cabinet|agence|laboratoires?|solutions|services|technologies|international)\b',
  caseSensitive: false,
);
final _addressWords = RegExp(
  r'\b(rue|avenue|av\.|bd|boulevard|lot|lotissement|zone|quartier|immeuble|imm\.|r[ée]sidence|[ée]tage|angle|route|km|b\.?p\.?|n°|hay|street|road|casablanca|rabat|k[ée]nitra|tanger|marrakech|f[èe]s|agadir|mekn[èe]s|oujda|t[ée]touan|mohammedia|sal[ée]|maroc|morocco|france|paris)\b',
  caseSensitive: false,
);
const _publicMail = {
  'gmail',
  'yahoo',
  'hotmail',
  'outlook',
  'live',
  'icloud',
  'menara',
  'ymail',
};

bool _looksLikeName(String line) {
  final words = line.split(' ');
  if (words.length < 2 || words.length > 4) return false;
  return words.every((w) => RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ'’.\-]+$").hasMatch(w));
}

/// Préfère l'adresse nominative à une adresse générique (contact@, info@…).
String _pickPersonalEmail(List<String> emails) {
  final generic = RegExp(
    r'^(contact|info|commercial|sales|hello|bonjour|accueil|direction)@',
    caseSensitive: false,
  );
  return emails.firstWhere(
    (e) => !generic.hasMatch(e),
    orElse: () => emails.first,
  );
}

/// 0 pour un mobile marocain (06/07, +2126/+2127), 1 sinon : le mobile passe en premier.
int _mobileRank(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'^(?:00212|212|0)[67]').hasMatch(d) ? 0 : 1;
}

String _plain(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String? _firstWhere(List<String> list, bool Function(String) test) {
  for (final l in list) {
    if (test(l)) return l;
  }
  return null;
}
