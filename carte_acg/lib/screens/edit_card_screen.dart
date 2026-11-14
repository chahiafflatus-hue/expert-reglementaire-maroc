import 'package:material_ui/material_ui.dart';

import '../models/card_data.dart';

/// Formulaire de création / modification de la carte du consultant.
class EditCardScreen extends StatefulWidget {
  const EditCardScreen({super.key, this.initial});
  final CardData? initial;

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _form = GlobalKey<FormState>();
  late final _prenom = TextEditingController(text: widget.initial?.prenom);
  late final _nom = TextEditingController(text: widget.initial?.nom);
  late final _titre = TextEditingController(text: widget.initial?.titre);
  late final _tel = TextEditingController(text: widget.initial?.tel);
  late final _email = TextEditingController(text: widget.initial?.email);
  late bool _brcgs = widget.initial?.brcgs ?? false;

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _titre, _tel, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      CardData(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        titre: _titre.text.trim(),
        tel: _tel.text.trim(),
        email: _email.text.trim(),
        brcgs: _brcgs,
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    Widget field(
      TextEditingController c,
      String label, {
      TextInputType? type,
      String? hint,
      String? Function(String?)? validator,
      TextCapitalization caps = TextCapitalization.none,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          keyboardType: type,
          textCapitalization: caps,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: validator ?? _required,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Créer ma carte' : 'Modifier ma carte',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            field(_prenom, 'Prénom', caps: TextCapitalization.words),
            field(_nom, 'Nom', caps: TextCapitalization.characters),
            field(
              _titre,
              'Poste',
              hint: 'Head of Consulting',
              caps: TextCapitalization.words,
            ),
            field(
              _tel,
              'Téléphone',
              type: TextInputType.phone,
              hint: '+212 6xx xxx xxx',
            ),
            field(
              _email,
              'Email',
              type: TextInputType.emailAddress,
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Email invalide',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('BRCGS Approved Consultant'),
              subtitle: const Text('Affiche le logo sur la carte'),
              value: _brcgs,
              onChanged: (v) => setState(() => _brcgs = v),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
