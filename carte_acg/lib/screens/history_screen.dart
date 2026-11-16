import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../models/share_entry.dart';
import '../services/contacts_db.dart';
import '../services/share_service.dart';

/// Historique des partages : à qui la carte (ou le lien de besoin) a été montrée, et quand.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ShareEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ContactsDb.instance.historyChanges.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    ContactsDb.instance.historyChanges.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await ContactsDb.instance.history();
    if (mounted) {
      setState(() {
        _entries = list;
        _loading = false;
      });
    }
  }

  void _open(ShareEntry entry) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => HistoryEntryScreen(entry: entry)),
    );
  }

  Future<void> _export() async {
    final contacts = await ContactsDb.instance.list();
    if (_entries.isEmpty && contacts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun historique à exporter.')),
      );
      return;
    }
    await shareContactsXlsx(contacts, history: _entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            tooltip: 'Exporter vers Excel',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _export,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const ShareEntry()),
        icon: const Icon(Icons.add),
        label: const Text('Noter un partage'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun partage noté.\n\nAprès avoir fait scanner votre QR code, '
            'notez ici la personne : la date est ajoutée automatiquement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kGris, height: 1.5),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final e = _entries[i];
        final besoin = e.kind == ShareEntry.kindBesoin;
        final who = [e.name, e.company].where((s) => s.isNotEmpty).join(' · ');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: kFond,
            foregroundColor: kBordeaux,
            child: Icon(
              besoin ? Icons.assignment_outlined : Icons.badge_outlined,
            ),
          ),
          title: Text(
            who.isEmpty ? 'Sans nom' : who,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${e.dateLabel} · ${e.kindLabel}'),
          onTap: () => _open(e),
        );
      },
    );
  }
}

/// Ajout / modification d'une ligne d'historique.
class HistoryEntryScreen extends StatefulWidget {
  const HistoryEntryScreen({super.key, required this.entry});
  final ShareEntry entry;

  @override
  State<HistoryEntryScreen> createState() => _HistoryEntryScreenState();
}

class _HistoryEntryScreenState extends State<HistoryEntryScreen> {
  late String _kind = widget.entry.kind;
  late final _name = TextEditingController(text: widget.entry.name);
  late final _company = TextEditingController(text: widget.entry.company);
  late final _phone = TextEditingController(text: widget.entry.phone);
  late final _email = TextEditingController(text: widget.entry.email);
  late final _note = TextEditingController(text: widget.entry.note);

  bool get _isNew => widget.entry.id == null;

  @override
  void dispose() {
    for (final c in [_name, _company, _phone, _email, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim(), company = _company.text.trim();
    if (name.isEmpty && company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez au moins un nom ou une société.'),
        ),
      );
      return;
    }
    await ContactsDb.instance.saveHistory(
      ShareEntry(
        id: widget.entry.id,
        kind: _kind,
        name: name,
        company: company,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        note: _note.text.trim(),
        // La date d'origine est conservée lors d'une modification.
        createdAt: widget.entry.createdAt ?? DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ContactsDb.instance.deleteHistory(widget.entry.id!);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    int maxLines = 1,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Noter un partage' : 'Partage'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _isNew
                ? 'La date et l\'heure sont enregistrées automatiquement.'
                : 'Partagé le ${widget.entry.dateLabel}',
            style: const TextStyle(color: kGris),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: ShareEntry.kindContact,
                label: Text('Contact'),
                icon: Icon(Icons.badge_outlined),
              ),
              ButtonSegment(
                value: ShareEntry.kindBesoin,
                label: Text('Besoin'),
                icon: Icon(Icons.assignment_outlined),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 16),
          _field(
            _name,
            'Nom de la personne',
            Icons.person_outline,
            caps: TextCapitalization.words,
          ),
          _field(
            _company,
            'Société',
            Icons.business_outlined,
            caps: TextCapitalization.words,
          ),
          _field(
            _phone,
            'Téléphone (facultatif)',
            Icons.phone_outlined,
            type: TextInputType.phone,
          ),
          _field(
            _email,
            'Email (facultatif)',
            Icons.mail_outline,
            type: TextInputType.emailAddress,
          ),
          _field(_note, 'Note (facultatif)', Icons.notes, maxLines: 3),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}
