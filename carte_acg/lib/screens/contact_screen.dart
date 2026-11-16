import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/contact.dart';
import '../models/vcard.dart';
import '../services/contacts_db.dart';
import '../services/share_service.dart';

/// Fiche d'un contact : vérification après un scan, consultation, modification, suppression.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.contact, this.rawText = ''});
  final Contact contact;

  /// Texte lu par l'OCR (affiché après un scan pour corriger les champs).
  final String rawText;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final _c = {
    for (final e in widget.contact.toMap().entries)
      if (Contact.columns.contains(e.key))
        e.key: TextEditingController(text: e.value as String),
  };

  bool get _isNew => widget.contact.id == null;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String key) => _c[key]!.text.trim();

  Contact get _current => Contact(
    id: widget.contact.id,
    name: _v('name'),
    title: _v('title'),
    company: _v('company'),
    phone: _v('phone'),
    email: _v('email'),
    website: _v('website'),
    address: _v('address'),
    note: _v('note'),
    imagePath: widget.contact.imagePath,
    createdAt: widget.contact.createdAt,
  );

  Future<void> _save() async {
    final c = _current;
    if (c.name.isEmpty && c.company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez au moins un nom ou une société.'),
        ),
      );
      return;
    }
    await ContactsDb.instance.save(c);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce contact ?'),
        content: const Text(
          'La fiche et la photo de la carte seront supprimées de ce téléphone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ContactsDb.instance.delete(widget.contact.id!);
    final image = widget.contact.imagePath;
    if (image != null && File(image).existsSync()) await File(image).delete();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune application ne peut ouvrir ce lien.'),
        ),
      );
    }
  }

  Widget _field(
    String key,
    String label,
    IconData icon, {
    TextInputType? type,
    int maxLines = 1,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        keyboardType: type,
        maxLines: maxLines,
        textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.contact.imagePath;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nouveau contact' : 'Contact'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            tooltip: 'Enregistrer',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (image != null && File(image).existsSync())
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(image), height: 180, fit: BoxFit.cover),
              ),
            ),
          if (_isNew && widget.rawText.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Vérifiez les champs lus sur la carte, corrigez si besoin, puis enregistrez.',
                style: TextStyle(color: kBordeaux, fontWeight: FontWeight.w600),
              ),
            ),
          _field(
            'name',
            'Nom',
            Icons.person_outline,
            caps: TextCapitalization.words,
          ),
          _field(
            'title',
            'Poste',
            Icons.work_outline,
            caps: TextCapitalization.words,
          ),
          _field(
            'company',
            'Société',
            Icons.business_outlined,
            caps: TextCapitalization.words,
          ),
          _field(
            'phone',
            'Téléphone',
            Icons.phone_outlined,
            type: TextInputType.phone,
          ),
          _field(
            'email',
            'Email',
            Icons.mail_outline,
            type: TextInputType.emailAddress,
          ),
          _field(
            'website',
            'Site web',
            Icons.language,
            type: TextInputType.url,
          ),
          _field('address', 'Adresse', Icons.place_outlined, maxLines: 2),
          _field('note', 'Note', Icons.notes, maxLines: 4),
          if (!_isNew)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_v('phone').isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(
                      Uri(scheme: 'tel', path: phoneDigits(_v('phone'))),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Appeler'),
                  ),
                if (_v('phone').isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launch(
                      Uri.parse(
                        'https://wa.me/${phoneDigits(_v('phone')).replaceAll('+', '')}',
                      ),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                if (_v('email').isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _launch(Uri(scheme: 'mailto', path: _v('email'))),
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: const Text('Email'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => shareVCard(
                    _current.name.isEmpty ? _current.company : _current.name,
                    _current.toVCard(),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager / ajouter au répertoire'),
                ),
              ],
            ),
          if (widget.rawText.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Texte lu sur la carte',
              style: TextStyle(fontWeight: FontWeight.w600, color: kGris),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kFond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                widget.rawText,
                style: const TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}
