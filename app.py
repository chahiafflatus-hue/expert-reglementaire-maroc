import streamlit as st
import google.generativeai as genai
from datetime import datetime

# Configuration de la page avec support PWA
st.set_page_config(
    page_title="Expert Réglementaire",
    page_icon="📋",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Meta tags pour PWA mobile (iOS/Android)
st.markdown("""
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="Expert Réglementaire">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
""", unsafe_allow_html=True)

# CSS personnalisé pour une meilleure apparence mobile
st.markdown("""
    <style>
    .main {
        padding: 1rem;
    }
    .stButton>button {
        width: 100%;
        background-color: #1f77b4;
        color: white;
        font-weight: bold;
        padding: 0.75rem;
        border-radius: 0.5rem;
        border: none;
        font-size: 1.1rem;
    }
    .stButton>button:hover {
        background-color: #1557a0;
    }
    h1 {
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .stTextArea>div>div>textarea {
        font-size: 1rem;
    }
    .source-box {
        background-color: #f0f8ff;
        border-left: 4px solid #1f77b4;
        padding: 1rem;
        margin: 1rem 0;
        border-radius: 0.5rem;
    }
    </style>
""", unsafe_allow_html=True)

# System Prompt pour l'Expert Réglementaire avec Web Search
SYSTEM_PROMPT = """
Ton Rôle :
Tu es un Expert Consultant Senior en Réglementation Agroalimentaire (QHSE & Regulatory Affairs). Tu produis des rapports d'aide à la décision pour des responsables qualité et directeurs d'usine. Tu maîtrises les référentiels Maroc (ONSSA), UE (EFSA), USA (FDA), International (Codex) et Retail (FCD).

IMPÉRATIF : Tu DOIS chercher sur le web les informations réglementaires à jour avant de répondre. N'invente JAMAIS de données.

Sources Prioritaires (RECHERCHE OBLIGATOIRE) :
- Maroc : site:onssa.gov.ma, site:imanor.gov.ma
- UE : site:eur-lex.europa.eu, site:efsa.europa.eu
- USA : site:fda.gov, site:ecfr.gov
- International : site:fao.org/fao-who-codexalimentarius
- Distribution : FCD (cahiers des charges)

Protocole de Travail OBLIGATOIRE :
1. RECHERCHER d'abord sur le web les textes officiels
2. EXTRAIRE les informations exactes des sources trouvées
3. CITER systématiquement les sources avec URLs
4. DISTINGUER ce qui est vérifié vs. extrapolé

Format de Sortie Obligatoire :

# MÉMO DE CONFORMITÉ RÉGLEMENTAIRE

**DATE :** {date_du_jour}  
**OBJET :** {sujet}

---

## 1. 📚 SOURCES CONSULTÉES

Liste numérotée des sites officiels consultés avec liens directs :

1. **[Nom Organisme] - [Titre Document]** (Consulté le: JJ/MM/AAAA)  
   🔗 [Lien direct](URL_EXACTE)  
   📅 Dernière MAJ: JJ/MM/AAAA

---

## 2. 🎯 SYNTHÈSE MANAGÉRIALE

Résumé exécutif de 3-4 lignes basé sur les sources consultées. Indique clairement :
- ✅ Conforme / ⚠️ À risque / ❌ Non-conforme
- La norme la plus stricte à respecter

---

## 3. 📋 TABLEAU DE CONFORMITÉ

| Référentiel | Exigence / Limite Réglementaire | Dates Clés | Source Vérifiée |
|-------------|--------------------------------|------------|-----------------|
| 🇲🇦 **Maroc (ONSSA)** | [Texte exact de la réglementation] | Publié: JJ/MM/AA<br>Applicable: JJ/MM/AA | [🔗 Lien](URL) |
| 🇪🇺 **UE (EUR-Lex)** | [Texte exact du règlement] | MAJ: JJ/MM/AA<br>Applicable: JJ/MM/AA | [🔗 Lien](URL) |
| 🇺🇸 **USA (FDA)** | [Texte exact CFR] | Effective: JJ/MM/AA | [🔗 Lien](URL) |
| 🌍 **Codex Alimentarius** | [Norme CXS] | Rév: AAAA | [🔗 Lien](URL) |

---

## 4. 📖 EXTRAITS RÉGLEMENTAIRES

Citations textuelles des documents sources :

**🇲🇦 ONSSA - [Titre du texte]:**
> "[Citation exacte du texte officiel...]"  
> — Arrêté n°XXX, Article Y, publié le JJ/MM/AAAA

**🇪🇺 EUR-Lex - [Titre du règlement]:**
> "[Citation exacte...]"  
> — Règlement (UE) n°XXXX/AAAA, Article Z

---

## 5. ⚖️ ANALYSE D'ÉCART (GAP ANALYSIS)

### Le Mieux-Disant (Standard Interne)
La norme la plus sévère est : [...]

### ⏰ Alertes Transitoires
- Textes publiés mais pas encore applicables : [...]

### ⚠️ Points de Vigilance FDA/FCD
- Spécificités étiquetage : [...]
- Méthodes d'analyse différentes : [...]

---

## 6. ✅ RECOMMANDATIONS OPÉRATIONNELLES

Actions concrètes immédiates :

1. **Court terme (< 1 mois) :**
   - [ ] Action 1
   - [ ] Action 2

2. **Moyen terme (1-3 mois) :**
   - [ ] Action 3

---

## 7. 📊 NIVEAU DE CONFIANCE

🟢 **Élevé** : Sources officielles vérifiées datant de moins de 6 mois  
🟡 **Moyen** : Sources datant de 6-12 mois ou sources secondaires  
🔴 **Faible** : Informations partielles, nécessite vérification approfondie

**Niveau actuel :** [INDIQUER ICI basé sur la fraîcheur des sources]

---

Ton et Style :
- Professionnel, factuel, "Corporate"
- TOUJOURS citer les sources avec URLs cliquables
- Vocabulaire technique précis (LMR, ARfD, DJA, plan de surveillance)
- Pas de phrases de remplissage. Droit au but.
"""

def initialize_gemini():
    """Initialize Gemini API with Google Search grounding"""
    try:
        api_key = st.secrets.get("GEMINI_API_KEY", None)
        if not api_key:
            st.error("⚠️ Clé API Gemini non configurée. Veuillez ajouter votre clé dans `.streamlit/secrets.toml`")
            st.stop()
        
        genai.configure(api_key=api_key)
        
        # Use Gemini 1.5 Flash with grounding for web search
        model = genai.GenerativeModel(
            model_name='gemini-1.5-flash-latest',
            generation_config={
                'temperature': 0.2,  # Un peu plus élevé pour utiliser le search
                'top_p': 0.95,
                'top_k': 40,
                'max_output_tokens': 8192,
            },
            tools=[{'google_search_retrieval': {}}]  # Enable Google Search!
        )
        
        return model
    except Exception as e:
        st.error(f"❌ Erreur lors de l'initialisation de Gemini : {str(e)}")
        st.stop()

def generate_report_with_search(model, user_question):
    """Generate regulatory report with web search using Gemini grounding"""
    try:
        # Ajouter la date actuelle au contexte
        current_date = datetime.now().strftime("%d/%m/%Y")
        
        # Construire le prompt avec instructions de recherche web
        search_prompt = f"""
{SYSTEM_PROMPT}

---

DATE DU JOUR : {current_date}

QUESTION DE L'UTILISATEUR :
{user_question}

INSTRUCTIONS SPÉCIALES :
1. RECHERCHE d'abord sur le web les textes réglementaires officiels pertinents
2. Privilégie les sites gouvernementaux (.gov, .europa.eu, .fao.org)
3. CITE systématiquement les URLs des sources consultées
4. EXTRAIT des citations exactes des textes officiels
5. PRÉCISE les dates de publication et d'application

Génère maintenant le rapport en respectant strictement le format demandé.
"""
        
        # Générer la réponse avec recherche web
        with st.spinner("🔍 Recherche sur le web et analyse réglementaire en cours..."):
            response = model.generate_content(search_prompt)
            
            # Afficher les sources si disponibles
            if hasattr(response, 'grounding_metadata') and response.grounding_metadata:
                with st.expander("🌐 Sources Web Consultées", expanded=False):
                    st.json(response.grounding_metadata)
            
            return response.text
    except Exception as e:
        st.error(f"❌ Erreur lors de la génération du rapport : {str(e)}")
        return None

def main():
    # Titre de l'application
    st.title("📋 Expert Réglementaire Agroalimentaire")
    st.success("✅ **Nouveau :** Recherche automatique sur le web des textes réglementaires officiels")
    st.markdown("---")
    
    # Initialize Gemini with Google Search
    model = initialize_gemini()
    
    # Interface utilisateur
    st.markdown("### 💬 Posez votre question réglementaire")
    st.info("💡 L'agent va rechercher automatiquement sur ONSSA, EUR-Lex, FDA, Codex Alimentarius et autres sources officielles")
    
    user_question = st.text_area(
        "Question :",
        placeholder="Ex: Quelle est la limite maximale de résidus d'aflatoxine B1 dans les amandes selon les normes ONSSA et UE ?",
        height=150,
        label_visibility="collapsed"
    )
    
    # Bouton de génération
    if st.button("🚀 Générer le Rapport avec Recherche Web"):
        if not user_question or user_question.strip() == "":
            st.warning("⚠️ Veuillez saisir une question avant de générer le rapport.")
        else:
            # Générer le rapport avec recherche web
            report = generate_report_with_search(model, user_question)
            
            if report:
                st.markdown("---")
                st.markdown("### 📄 Rapport Réglementaire")
                st.markdown(report)
                
                # Option de téléchargement
                st.download_button(
                    label="📥 Télécharger le rapport (Markdown)",
                    data=report,
                    file_name=f"rapport_reglementaire_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md",
                    mime="text/markdown"
                )
    
    # Footer
    st.markdown("---")
    st.markdown(
        """
        <div style='text-align: center; color: #666; font-size: 0.9rem;'>
            <p>🔒 Application sécurisée pour usage interne | Expert Réglementaire v2.0 avec Recherche Web</p>
        </div>
        """,
        unsafe_allow_html=True
    )

if __name__ == "__main__":
    main()
