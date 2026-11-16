import 'package:material_ui/material_ui.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../config.dart';
import '../models/card_data.dart';
import '../services/nfc_records.dart';

Future<void> showNfcSheet(BuildContext context, CardData card) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _NfcSheet(card: card),
  );
}

/// Écrit la carte sur une puce NFC (carte PVC ou autocollant NTAG).
class _NfcSheet extends StatefulWidget {
  const _NfcSheet({required this.card});
  final CardData card;

  @override
  State<_NfcSheet> createState() => _NfcSheetState();
}

class _NfcSheetState extends State<_NfcSheet> {
  String _status = '';
  bool _writing = false;
  bool _session = false;

  @override
  void dispose() {
    if (_session) NfcManager.instance.stopSession();
    super.dispose();
  }

  void _set(String status, {bool writing = false}) {
    if (mounted) {
      setState(() {
        _status = status;
        _writing = writing;
      });
    }
  }

  Future<void> _write(NdefRecord record) async {
    final message = NdefMessage(records: [record]);
    try {
      if (await NfcManager.instance.checkAvailability() !=
          NfcAvailability.enabled) {
        _set('Le NFC est désactivé ou absent sur ce téléphone.');
        return;
      }
      _set('Approchez la puce NFC du dos du téléphone…', writing: true);
      _session = true;
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessageIos: 'Approchez la puce NFC du haut de l\'iPhone.',
        onDiscovered: (tag) async {
          String? error;
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              error = 'Cette puce n\'est pas au format NDEF.';
            } else if (!ndef.isWritable) {
              error = 'Cette puce est verrouillée en écriture.';
            } else if (message.byteLength > ndef.maxSize) {
              error =
                  'Puce trop petite (${ndef.maxSize} octets, ${message.byteLength} nécessaires). '
                  'Utilisez une puce NTAG215 ou NTAG216.';
            } else {
              await ndef.write(message: message);
            }
          } catch (_) {
            error =
                'Écriture interrompue. Gardez la puce immobile et réessayez.';
          }
          _session = false;
          await NfcManager.instance.stopSession(
            alertMessageIos: error == null ? 'Puce écrite' : null,
            errorMessageIos: error,
          );
          _set(error ?? 'Puce NFC écrite ✓');
        },
      );
    } catch (_) {
      _session = false;
      _set('Le NFC n\'est pas disponible sur ce téléphone.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Écrire ma carte sur une puce NFC',
              style: TextStyle(
                color: kBordeaux,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre interlocuteur approche son téléphone de la puce (carte ou autocollant NFC) '
              'pour recevoir votre carte. Après une modification de vos informations, réécrivez la puce.',
              style: TextStyle(color: kGris, height: 1.45, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _writing
                  ? null
                  : () => _write(uriRecord(widget.card.webLink)),
              icon: const Icon(Icons.link),
              label: const Text('Lien web (iPhone + Android)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _writing
                  ? null
                  : () => _write(vcardRecord(widget.card.toVCard())),
              icon: const Icon(Icons.contact_page_outlined),
              label: const Text('Fiche contact (Android, sans internet)'),
            ),
            const SizedBox(height: 14),
            if (_status.isNotEmpty)
              Row(
                children: [
                  if (_writing)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(
                        color: kBordeaux,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
