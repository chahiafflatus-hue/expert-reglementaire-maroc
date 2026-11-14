import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/card_data.dart';
import '../models/vcard.dart';
import '../services/profile_store.dart';
import '../services/share_service.dart';
import 'edit_card_screen.dart';
import 'nfc_sheet.dart';

/// Écran principal : la carte du consultant, avec son QR code à faire scanner.
class MyCardScreen extends StatefulWidget {
  const MyCardScreen({super.key});

  @override
  State<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends State<MyCardScreen> {
  CardData? _card;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((c) {
      if (!mounted) return;
      setState(() {
        _card = c;
        _loading = false;
      });
    });
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<CardData>(
      MaterialPageRoute(builder: (_) => EditCardScreen(initial: _card)),
    );
    if (updated == null) return;
    await ProfileStore.save(updated);
    if (mounted) setState(() => _card = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final card = _card;
    if (card == null) return _Welcome(onCreate: _edit);

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Identity(card: card),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        // Le QR code occupe la hauteur restante ; sur un petit écran la page défile.
                        child: _QrBlock(
                          data: card.toVCard(),
                          size: (box.maxHeight - 360).clamp(170.0, 240.0),
                        ),
                      ),
                      _Actions(card: card, onEdit: _edit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const _Footer(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kBordeaux,
      padding: EdgeInsets.fromLTRB(
        26,
        MediaQuery.paddingOf(context).top + 18,
        26,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/logo-blanc.png', width: 170, semanticLabel: kOrg),
          const SizedBox(height: 10),
          Container(width: 26, height: 1, color: Colors.white60),
          const SizedBox(height: 9),
          const Text(
            kSlogan,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 10,
      letterSpacing: 2,
    );
    return Container(
      width: double.infinity,
      color: kBordeaux,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
      child: const Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(
            'AFFLATUSCONSULTING.COM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text('RABAT · KÉNITRA · MAROC', style: style),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.card});
  final CardData card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                card.nomComplet,
                style: const TextStyle(
                  color: kBordeaux,
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (card.brcgs)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Image.asset(
                  'assets/brcgs.png',
                  width: 100,
                  semanticLabel: 'BRCGS Approved Consultant',
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          card.titre.toUpperCase(),
          style: const TextStyle(
            color: kGris,
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          Icons.phone_outlined,
          card.tel,
          Uri(scheme: 'tel', path: phoneDigits(card.tel)),
        ),
        _InfoRow(
          Icons.mail_outline,
          card.email,
          Uri(scheme: 'mailto', path: card.email),
        ),
        if (card.email2.isNotEmpty)
          _InfoRow(
            Icons.mail_outline,
            card.email2,
            Uri(scheme: 'mailto', path: card.email2),
          ),
        _InfoRow(
          Icons.home_outlined,
          kContactEmail,
          Uri(scheme: 'mailto', path: kContactEmail),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text, this.uri);
  final IconData icon;
  final String text;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kBordeaux),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: kGris, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.data, required this.size});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLigne, width: 1.5),
            ),
            child: QrImageView(
              data: data,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              semanticsLabel: 'QR code de ma carte de visite',
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'SCANNEZ POUR ENREGISTRER\nMON CONTACT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kBordeaux,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

final _compact = ButtonStyle(
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 6)),
  minimumSize: WidgetStateProperty.all(const Size(0, 46)),
);

class _Actions extends StatelessWidget {
  const _Actions({required this.card, required this.onEdit});
  final CardData card;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: _compact,
            onPressed: () => shareVCard(card.nomComplet, card.toVCard()),
            child: const Text('Partager'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            style: _compact,
            onPressed: () => showNfcSheet(context, card),
            child: const Text('NFC'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            style: _compact,
            onPressed: onEdit,
            child: const Text('Modifier'),
          ),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.badge_outlined, size: 56, color: kBordeaux),
                const SizedBox(height: 16),
                const Text(
                  'Créez votre carte de visite',
                  style: TextStyle(
                    color: kBordeaux,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vos informations restent sur ce téléphone et sont modifiables à tout moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kGris, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onCreate,
                  child: const Text('Créer ma carte'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
