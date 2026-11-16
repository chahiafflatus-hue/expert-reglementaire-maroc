/// Construction de fiches contact au format vCard 3.0.
String _esc(String v) => v
    .replaceAll('\\', '\\\\')
    .replaceAll('\n', '\\n')
    .replaceAllMapped(RegExp('[,;]'), (m) => '\\${m[0]}');

/// Ne garde que les chiffres et le « + » initial d'un numéro.
String phoneDigits(String tel) {
  final t = tel.trim();
  final d = t.replaceAll(RegExp(r'\D'), '');
  return t.startsWith('+') ? '+$d' : d;
}

String buildVCard({
  String given = '',
  String family = '',
  String? fullName,
  String org = '',
  String title = '',
  List<String> phones = const [],
  List<String> emails = const [],
  String website = '',
  String extraUrl = '',
  String extraUrlLabel = '',
  String city = '',
  String country = '',
  String street = '',
  String note = '',
}) {
  final fn = (fullName ?? '$given $family').trim();
  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'N:${_esc(family)};${_esc(given.isEmpty && family.isEmpty ? fn : given)};;;',
    'FN:${_esc(fn)}',
    if (org.isNotEmpty) 'ORG:${_esc(org)}',
    if (title.isNotEmpty) 'TITLE:${_esc(title)}',
    for (final p in phones)
      if (phoneDigits(p).isNotEmpty) 'TEL;TYPE=CELL:${phoneDigits(p)}',
    for (var i = 0; i < emails.length; i++)
      if (emails[i].isNotEmpty)
        '${i == 0 ? 'EMAIL;TYPE=WORK' : 'EMAIL'}:${emails[i]}',
    if (website.isNotEmpty) 'URL:$website',
    if (extraUrl.isNotEmpty) ...[
      'item1.URL:$extraUrl',
      if (extraUrlLabel.isNotEmpty) 'item1.X-ABLabel:${_esc(extraUrlLabel)}',
    ],
    if (street.isNotEmpty || city.isNotEmpty || country.isNotEmpty)
      'ADR;TYPE=WORK:;;${_esc(street)};${_esc(city)};;;${_esc(country)}',
    if (note.isNotEmpty) 'NOTE:${_esc(note)}',
    'END:VCARD',
    '',
  ];
  return lines.join('\r\n');
}
