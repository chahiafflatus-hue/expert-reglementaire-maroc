import 'vcard.dart';

/// Une carte de visite reçue et enregistrée dans la base de contacts.
class Contact {
  const Contact({
    this.id,
    this.name = '',
    this.title = '',
    this.company = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.note = '',
    this.imagePath,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String title;
  final String company;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String note;

  /// Photo de la carte scannée (fichier dans le dossier de l'application).
  final String? imagePath;
  final DateTime? createdAt;

  static const columns = [
    'name',
    'title',
    'company',
    'phone',
    'email',
    'website',
    'address',
    'note', //
  ];

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'title': title,
    'company': company,
    'phone': phone,
    'email': email,
    'website': website,
    'address': address,
    'note': note,
    'image_path': imagePath,
    'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
  };

  factory Contact.fromMap(Map<String, Object?> m) => Contact(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    title: m['title'] as String? ?? '',
    company: m['company'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    email: m['email'] as String? ?? '',
    website: m['website'] as String? ?? '',
    address: m['address'] as String? ?? '',
    note: m['note'] as String? ?? '',
    imagePath: m['image_path'] as String?,
    createdAt: m['created_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int)
        : null,
  );

  Contact copyWith({int? id, String? imagePath}) => Contact(
    id: id ?? this.id,
    name: name,
    title: title,
    company: company,
    phone: phone,
    email: email,
    website: website,
    address: address,
    note: note,
    imagePath: imagePath ?? this.imagePath,
    createdAt: createdAt,
  );

  String toVCard() => buildVCard(
    fullName: name.isEmpty ? company : name,
    org: company,
    title: title,
    phones: [if (phone.isNotEmpty) phone],
    emails: [if (email.isNotEmpty) email],
    website: website,
    street: address,
    note: note,
  );
}
