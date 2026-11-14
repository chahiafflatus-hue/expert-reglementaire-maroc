import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/contact.dart';
import '../services/card_scanner.dart';
import '../services/contacts_db.dart';
import '../services/share_service.dart';
import 'contact_screen.dart';

/// Base de contacts : les cartes de visite reçues, scannées par OCR ou saisies à la main.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  List<Contact> _contacts = [];
  bool _loading = true;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await ContactsDb.instance.list(query: _search.text);
    if (mounted) {
      setState(() {
        _contacts = list;
        _loading = false;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(Contact contact, {String rawText = ''}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ContactScreen(contact: contact, rawText: rawText),
      ),
    );
    await _reload();
  }

  Future<void> _scan() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Photographier une carte'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir une photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _scanning = true);
    try {
      final result = await scanBusinessCard(source);
      if (result == null || !mounted) return;
      if (result.error != null) {
        _snack('Lecture automatique impossible : ${result.error}');
      } else if (result.rawText.trim().isEmpty) {
        _snack(
          'Aucun texte lu sur la photo. Complétez la fiche à la main ou réessayez.',
        );
      }
      await _open(result.contact, rawText: result.rawText);
    } catch (e) {
      _snack('Le scan a échoué : $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _export() async {
    final all = await ContactsDb.instance.list();
    if (all.isEmpty) {
      _snack('Aucun contact à exporter.');
      return;
    }
    await shareContactsXlsx(all);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            tooltip: 'Ajouter à la main',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _open(const Contact()),
          ),
          IconButton(
            tooltip: 'Exporter vers Excel',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _export,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _scan,
        icon: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.document_scanner_outlined),
        label: Text(_scanning ? 'Lecture…' : 'Scanner une carte'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => _reload(),
              decoration: const InputDecoration(
                hintText: 'Rechercher (nom, société, téléphone…)',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _search.text.isEmpty
                ? 'Aucun contact pour le moment.\nScannez une carte de visite pour commencer.'
                : 'Aucun contact ne correspond à cette recherche.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kGris, height: 1.5),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final c = _contacts[i];
        final title = c.name.isNotEmpty
            ? c.name
            : (c.company.isNotEmpty ? c.company : 'Sans nom');
        final subtitle = [
          c.title,
          if (c.name.isNotEmpty) c.company,
        ].where((s) => s.isNotEmpty).join(' · ');
        final image = c.imagePath;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: kFond,
            foregroundColor: kBordeaux,
            backgroundImage: image != null && File(image).existsSync()
                ? FileImage(File(image))
                : null,
            child: image == null
                ? Text(title.characters.first.toUpperCase())
                : null,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _open(c),
        );
      },
    );
  }
}
