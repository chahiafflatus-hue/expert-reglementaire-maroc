# Carte ACG

Application Flutter (Android et iOS) de carte de visite digitale pour Afflatus Consulting Group.

## Fonctions

- **Ma carte** : carte du consultant, saisie une fois et modifiable à tout moment (stockée sur le téléphone).
- **QR code** : contient la fiche contact (vCard) avec le site web et le lien « Exprimez votre besoin ».
  L'interlocuteur le scanne avec son appareil photo ; fonctionne sans internet.
- **NFC** : écrit la carte sur une puce NFC (carte PVC ou autocollant NTAG215/216), soit comme lien web
  (lu par iPhone et Android), soit comme fiche contact (Android, sans internet).
- **Partager** : envoie la fiche contact `.vcf` par WhatsApp, email, etc.
- **Contacts** : photographier une carte de visite reçue ; le texte est lu par OCR sur l'appareil
  (Google ML Kit), les champs sont préremplis puis vérifiés avant enregistrement dans une base locale
  (SQLite). Recherche, appel, WhatsApp, email, export de la base en fichier Excel (.xlsx).

Aucune donnée ne quitte le téléphone : pas de serveur, pas de compte.

## Compiler

```bash
flutter pub get
flutter test
flutter build apk --release        # Android : build/app/outputs/flutter-apk/app-release.apk
flutter build ipa                  # iOS : nécessite un Mac, Xcode et un compte Apple Developer
```

L'APK est aussi compilé automatiquement par GitHub Actions (workflow « Carte ACG – APK Android »),
à télécharger dans les artefacts de l'exécution.

### Notes

- L'APK de release est signé avec la clé de debug (suffisant pour une installation interne).
  Pour le Play Store, configurer une clé de signature dans `android/app/build.gradle.kts`.
- iOS : dans Xcode, ajouter la capacité *Near Field Communication Tag Reading* (fichier
  `ios/Runner/Runner.entitlements` fourni) et le bundle `LatinOCRResources.bundle` de ML Kit
  (voir la documentation de `google_mlkit_text_recognition`).
- Les coordonnées communes (société, site, lien de besoin, adresse de la page web des cartes)
  sont dans `lib/config.dart`.
- Le lien écrit sur les puces NFC ouvre la page web du dossier `docs/` : elle doit être publiée
  (GitHub Pages) à l'adresse `kWebCardBase`.
