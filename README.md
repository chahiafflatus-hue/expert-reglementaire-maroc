# 📋 Expert Réglementaire Agroalimentaire - Application Web (PWA)

Application Web Progressive sécurisée pour usage interne sur mobile. Expert en réglementation agroalimentaire powered by Google Gemini AI.

## 🎯 Description

Cette application fournit des rapports d'aide à la décision réglementaire pour les responsables qualité et directeurs d'usine. Elle couvre les référentiels :
- 🇲🇦 **Maroc** : ONSSA, Loi 28-07, IMANOR
- 🇪🇺 **Union Européenne** : EUR-Lex, EFSA
- 🇺🇸 **USA** : FDA, FSMA
- 🌍 **International** : Codex Alimentarius
- 🛒 **Distribution** : FCD

## 📁 Structure du Projet

```
KNOWLEDGE BASE/
├── app.py                      # Application principale
├── requirements.txt            # Dépendances Python
├── .streamlit/
│   └── secrets.toml           # Configuration API (à personnaliser)
└── README.md                  # Documentation
```

## ⚙️ Installation Locale

### Prérequis
- Python 3.8 ou supérieur
- Clé API Google Gemini ([Obtenir une clé](https://aistudio.google.com/app/apikey))

### Étapes d'installation

1. **Cloner ou télécharger le projet**
   ```bash
   cd "c:\Users\pc\Desktop\my work\veille reglementaire\KNOWLEDGE BASE"
   ```

2. **Créer un environnement virtuel**
   ```bash
   python -m venv venv
   ```

3. **Activer l'environnement virtuel**
   - Windows :
     ```bash
     .\venv\Scripts\activate
     ```
   - Mac/Linux :
     ```bash
     source venv/bin/activate
     ```

4. **Installer les dépendances**
   ```bash
   pip install -r requirements.txt
   ```

5. **Configurer la clé API**
   - Ouvrir `.streamlit/secrets.toml`
   - Remplacer `"your-api-key-here"` par votre vraie clé API Gemini

6. **Lancer l'application**
   ```bash
   streamlit run app.py
   ```

L'application s'ouvrira automatiquement dans votre navigateur à l'adresse `http://localhost:8501`

## 🚀 Déploiement sur Streamlit Cloud (GRATUIT)

Pour accéder à l'application depuis votre téléphone, déployez-la gratuitement sur Streamlit Cloud :

### Étape 1 : Préparer le code sur GitHub

1. **Créer un compte GitHub** (si vous n'en avez pas) : [github.com](https://github.com)

2. **Créer un nouveau repository**
   - Aller sur GitHub → New Repository
   - Nom : `expert-reglementaire`
   - Type : Public ou Private
   - Cliquer sur "Create repository"

3. **Uploader les fichiers**
   - Glisser-déposer tous les fichiers du projet sur GitHub
   - **IMPORTANT** : Ne pas uploader le fichier `secrets.toml` sur GitHub !
   - Fichiers à uploader :
     - ✅ `app.py`
     - ✅ `requirements.txt`
     - ✅ `README.md`
     - ❌ `.streamlit/secrets.toml` (NE PAS UPLOADER - contient votre clé API)

### Étape 2 : Déployer sur Streamlit Cloud

1. **Créer un compte Streamlit Cloud**
   - Aller sur [share.streamlit.io](https://share.streamlit.io)
   - Se connecter avec votre compte GitHub

2. **Déployer l'application**
   - Cliquer sur "New app"
   - Sélectionner votre repository `expert-reglementaire`
   - Main file path : `app.py`
   - Cliquer sur "Advanced settings"

3. **Configurer les secrets (Clé API)**
   - Dans "Secrets", copier-coller :
     ```toml
     GEMINI_API_KEY = "votre-vraie-clé-api-ici"
     ```
   - Cliquer sur "Deploy"

4. **Attendre le déploiement** (2-3 minutes)

### Étape 3 : Accéder sur mobile

Une fois déployée, vous recevrez une URL du type :
```
https://expert-reglementaire-xxxxx.streamlit.app
```

**Sur iPhone/iPad (iOS) :**
1. Ouvrir l'URL dans Safari
2. Appuyer sur le bouton "Partager" 📤
3. Sélectionner "Sur l'écran d'accueil"
4. L'app apparaîtra comme une vraie application !

**Sur Android :**
1. Ouvrir l'URL dans Chrome
2. Menu (⋮) → "Ajouter à l'écran d'accueil"
3. L'app apparaîtra comme une vraie application !

## 📱 Fonctionnalités PWA

L'application est optimisée pour mobile :
- ✅ Fonctionne comme une app native
- ✅ Icône sur l'écran d'accueil
- ✅ Mode plein écran (sans barre d'adresse)
- ✅ Interface responsive et tactile
- ✅ Téléchargement des rapports en Markdown

## 🔐 Sécurité

- **Clé API sécurisée** : Stockée dans Streamlit Cloud Secrets
- **Usage interne** : Configurer l'authentification si nécessaire
- **HTTPS** : Automatique sur Streamlit Cloud

## 💡 Utilisation

1. **Poser une question réglementaire**
   - Ex: "Quelle est la limite d'aflatoxine B1 dans les amandes selon ONSSA et UE ?"

2. **Cliquer sur "Générer le Rapport"**

3. **Recevoir un rapport structuré** avec :
   - Synthèse managériale
   - Tableau de conformité multi-référentiels
   - Analyse d'écart (Gap Analysis)
   - Recommandations opérationnelles

4. **Télécharger le rapport** (format Markdown)

## 🆘 Dépannage

### Erreur "Clé API non configurée"
- Vérifier que `.streamlit/secrets.toml` contient une vraie clé API
- Sur Streamlit Cloud : vérifier les "Secrets" dans les paramètres de l'app

### L'app ne démarre pas
- Vérifier que Python 3.8+ est installé : `python --version`
- Réinstaller les dépendances : `pip install -r requirements.txt`

### Problèmes de déploiement
- Vérifier que `requirements.txt` est bien dans le repository
- S'assurer que la clé API est configurée dans Streamlit Cloud Secrets

## 📞 Support

Pour toute question ou assistance technique, contactez l'administrateur système.

---

**Version** : 1.0  
**Dernière mise à jour** : Décembre 2025  
**Technologie** : Python 3.x, Streamlit, Google Gemini AI

## 💳 Carte de visite digitale (dossier `docs/`)

Application web installable (PWA), indépendante de l'application Streamlit : chaque consultant
l'installe sur son téléphone, y saisit ses coordonnées (modifiables à tout moment) et partage sa
carte par **QR code** (fiche contact vCard, fonctionne hors connexion) ou par **NFC** (lien écrit
sur une carte ou un autocollant NFC).

- Aucune donnée personnelle n'est stockée dans ce dépôt ni sur un serveur : la carte reste dans le
  téléphone du consultant, et le lien partagé la transporte dans son fragment (`#c=…`).
- Hébergement : GitHub Pages, *Settings › Pages › Deploy from a branch › dossier `/docs`*.
- Test local : `cd docs && python3 -m http.server 8000`.

## 📱 Application mobile « Carte ACG » (dossier `carte_acg/`)

Application Flutter Android / iOS : carte de visite modifiable avec QR code et NFC, scan des cartes
reçues par OCR et base de contacts locale. Voir [`carte_acg/README.md`](carte_acg/README.md).
