/// Une ligne de l'historique : la carte (ou le lien de besoin) a été partagée avec quelqu'un.
///
/// L'application ne peut pas savoir qui scanne un QR code : chaque ligne est notée par
/// le consultant au moment du partage.
class ShareEntry {
  const ShareEntry({
    this.id,
    this.kind = kindContact,
    this.name = '',
    this.company = '',
    this.phone = '',
    this.email = '',
    this.note = '',
    this.createdAt,
  });

  static const kindContact = 'contact';
  static const kindBesoin = 'besoin';

  final int? id;

  /// [kindContact] (QR du contact) ou [kindBesoin] (QR d'expression de besoin).
  final String kind;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String note;
  final DateTime? createdAt;

  String get kindLabel =>
      kind == kindBesoin ? 'Expression de besoin' : 'Contact';

  /// Date au format jj/mm/aaaa hh:mm.
  String get dateLabel {
    final d = createdAt;
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'kind': kind,
    'name': name,
    'company': company,
    'phone': phone,
    'email': email,
    'note': note,
    'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
  };

  factory ShareEntry.fromMap(Map<String, Object?> m) => ShareEntry(
    id: m['id'] as int?,
    kind: m['kind'] as String? ?? kindContact,
    name: m['name'] as String? ?? '',
    company: m['company'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    email: m['email'] as String? ?? '',
    note: m['note'] as String? ?? '',
    createdAt: m['created_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int)
        : null,
  );
}
