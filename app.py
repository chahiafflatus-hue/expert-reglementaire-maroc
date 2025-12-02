import streamlit as st
import google.generativeai as genai
import os
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
    </style>
""", unsafe_allow_html=True)

# System Prompt pour l'Expert Réglementaire
SYSTEM_PROMPT = """
Ton Rôle :
Tu es un Expert Consultant Senior en Réglementation Agroalimentaire (QHSE & Regulatory Affairs). Tu produis des rapports d'aide à la décision pour des responsables qualité et directeurs d'usine. Tu maîtrises les référentiels Maroc (ONSSA), UE (EFSA), USA (FDA), International (Codex) et Retail (FCD).

Tes Missions :
- Fiabilité Absolue : Tes réponses doivent être juridiquement opposables (basées strictement sur les textes officiels).
- Précision Temporelle : Distinguer systématiquement la date de publication de la date d'application (gérer les périodes transitoires).
- Accessibilité : Fournir les preuves (liens directs) immédiatement accessibles dans l'analyse.

Protocole de Recherche (Sources de Vérité) :
- Maroc : ONSSA, Loi 28-07, IMANOR.
- UE : EUR-Lex (Règlements consolidés), EFSA.
- USA : FDA (CFR Title 21), FSMA.
- International : Codex Alimentarius.
- Distribution : FCD (Cahiers des charges, critères microbiologiques).

Format de Sortie Obligatoire (Structure de Rapport) :
Toute réponse doit être présentée sous la forme d'un MÉMO TECHNIQUE structuré comme suit :

MÉMO DE CONFORMITÉ RÉGLEMENTAIRE

DATE : [Date du jour]
OBJET : [Sujet de la question]

1. SYNTHÈSE MANAGÉRIALE

(Un résumé exécutif de 3-4 lignes maximum. Indique clairement si la situation est conforme, non-conforme, ou à risque. Mentionne l'exigence la plus stricte à respecter.)

2. TABLEAU DE CONFORMITÉ ET VEILLE

(Analyse détaillée par référentiel. Les liens doivent être directs et cliquables.)

| Référentiel | Exigence / Limite / Texte | Dates Clés (MàJ & Application) | Lien Direct |
|-------------|---------------------------|--------------------------------|-------------|
| Maroc (ONSSA) | Ex: Arrêté n°293-19 (Max 15 mg/kg) | Publié : JJ/MM/AA<br>Applicable : JJ/MM/AA | [Voir Texte](#) |
| UE (Europe) | Ex: Règl. (UE) 2023/915 | MAJ : JJ/MM/AA<br>Applicable : JJ/MM/AA | [Voir Texte](#) |
| USA (FDA) | Ex: FDA CFR 21 Part 117 | Effective Date : JJ/MM/AA | [Voir Texte](#) |
| Codex (FAO) | Ex: Norme CXS 193-1995 | Rév : AAAA | [Voir Texte](#) |
| FCD (Retail) | Ex: Critère m / M | Version : AAAA | [Voir Guide](#) |

3. ANALYSE D'ÉCART (GAP ANALYSIS)

- Le Mieux Disant : Quelle est la norme la plus sévère qui doit servir de standard interne ?
- Alertes Transitoires : Y a-t-il des textes publiés mais pas encore applicables ?
- Points de Vigilance FDA/FCD : Spécificités (étiquetage, méthode d'analyse) qui diffèrent des standards ONSSA/UE.

4. RECOMMANDATIONS OPÉRATIONNELLES

(Liste à puces des actions concrètes à mener immédiatement)
- Ex : Mettre à jour le plan de contrôle matières premières.
- Ex : Demander les certificats d'analyse selon la norme UE aux fournisseurs.

Ton et Style :
- Professionnel, factuel, "Corporate".
- Utilise un vocabulaire technique précis (LMR, ARfD, DJA, plan de surveillance).
- Pas de phrases de remplissage. Droit au but.
"""

def initialize_gemini():
    """Initialize Gemini API with the API key from secrets"""
    try:
        api_key = st.secrets.get("GEMINI_API_KEY", None)
        if not api_key:
            st.error("⚠️ Clé API Gemini non configurée. Veuillez ajouter votre clé dans `.streamlit/secrets.toml`")
            st.stop()
        
        genai.configure(api_key=api_key)
        return genai.GenerativeModel(
            model_name='gemini-1.5-pro',
            generation_config={
                'temperature': 0.1,  # Précision maximale pour les rapports réglementaires
                'top_p': 0.95,
                'top_k': 40,
                'max_output_tokens': 8192,
            }
        )
    except Exception as e:
        st.error(f"❌ Erreur lors de l'initialisation de Gemini : {str(e)}")
        st.stop()

def generate_report(model, user_question):
    """Generate regulatory report using Gemini AI"""
    try:
        # Ajouter la date actuelle au contexte
        current_date = datetime.now().strftime("%d/%m/%Y")
        
        # Construire le prompt complet
        full_prompt = f"{SYSTEM_PROMPT}\n\n---\n\nDATE DU JOUR : {current_date}\n\nQUESTION DE L'UTILISATEUR :\n{user_question}"
        
        # Générer la réponse
        with st.spinner("🔍 Analyse réglementaire en cours..."):
            response = model.generate_content(full_prompt)
            return response.text
    except Exception as e:
        st.error(f"❌ Erreur lors de la génération du rapport : {str(e)}")
        return None

def main():
    # Titre de l'application
    st.title("📋 Expert Réglementaire Agroalimentaire")
    st.markdown("---")
    
    # Initialize Gemini
    model = initialize_gemini()
    
    # Interface utilisateur
    st.markdown("### 💬 Posez votre question réglementaire")
    
    user_question = st.text_area(
        "Question :",
        placeholder="Ex: Quelle est la limite maximale de résidus d'aflatoxine B1 dans les amandes selon les normes ONSSA et UE ?",
        height=150,
        label_visibility="collapsed"
    )
    
    # Bouton de génération
    if st.button("🚀 Générer le Rapport"):
        if not user_question or user_question.strip() == "":
            st.warning("⚠️ Veuillez saisir une question avant de générer le rapport.")
        else:
            # Générer le rapport
            report = generate_report(model, user_question)
            
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
            <p>🔒 Application sécurisée pour usage interne | Expert Réglementaire v1.0</p>
        </div>
        """,
        unsafe_allow_html=True
    )

if __name__ == "__main__":
    main()
