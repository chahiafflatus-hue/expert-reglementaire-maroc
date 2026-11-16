# L'application n'utilise que la reconnaissance de texte latin. Le plugin ML Kit référence
# aussi les modèles chinois, devanagari, japonais et coréen, qui ne sont pas embarqués :
# sans ces règles, R8 arrête la compilation sur ces classes absentes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
