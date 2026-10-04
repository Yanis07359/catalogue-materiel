from pathlib import Path
import re

controller = Path("src/main/java/com/example/catalogue/SiteController.java")
index_file = Path("src/main/resources/templates/index.html")
css_file = Path("src/main/resources/static/css/style.css")

# ------------------------------------------------------------
# 1. Contrôleur : deux annonces récentes + toutes les autres
# ------------------------------------------------------------
java = controller.read_text(encoding="utf-8")

nouvelle_methode = '''@GetMapping("/")
    public String accueil(Model model) {
        var recentes = annonceStore.findRecentes(2);

        var idsRecentes = recentes.stream()
                .map(Annonce::id)
                .collect(java.util.stream.Collectors.toSet());

        var autresAnnonces = annonceStore.findAll().stream()
                .filter(annonce -> !idsRecentes.contains(annonce.id()))
                .toList();

        model.addAttribute("annonces", recentes);
        model.addAttribute("autresAnnonces", autresAnnonces);

        return "index";
    }'''

pattern = r'@GetMapping$"/"$\s*public String accueil$Model model$\s*\{.*?return "index";\s*\}'

java_modifie, nombre = re.subn(
    pattern,
    nouvelle_methode,
    java,
    count=1,
    flags=re.DOTALL
)

if nombre != 1:
    raise SystemExit(
        "Impossible de trouver automatiquement la méthode accueil dans SiteController.java"
    )

controller.write_text(java_modifie, encoding="utf-8")

# ------------------------------------------------------------
# 2. Page d'accueil : ajouter la section des autres annonces
# ------------------------------------------------------------
html = index_file.read_text(encoding="utf-8")

if "yns-autres-annonces" not in html:
    debut = re.search(
        r'<div\s+class="[^"]*\bgrille\b[^"]*"[^>]*>',
        html
    )

    if not debut:
        raise SystemExit(
            "Impossible de trouver la grille des annonces dans index.html"
        )

    position_debut = debut.start()
    position = debut.end()
    profondeur = 1

    balises = re.compile(r'<div\b[^>]*>|</div\s*>', re.IGNORECASE)

    for balise in balises.finditer(html, position):
        if balise.group().lower().startswith("<div"):
            profondeur += 1
        else:
            profondeur -= 1

        if profondeur == 0:
            position_fin = balise.end()
            break
    else:
        raise SystemExit("La grille HTML semble ne pas être correctement fermée.")

    grille_recente = html[position_debut:position_fin]

    grille_autres = grille_recente.replace(
        "${annonces}",
        "${autresAnnonces}"
    )

    nouvelle_section = f'''

        <div class="yns-autres-annonces"
             th:if="${{autresAnnonces != null and !#lists.isEmpty(autresAnnonces)}}">

            <div class="titre-section yns-autres-titre">
                <div>
                    <span class="surtitre">Catalogue</span>
                    <h2>Autres annonces</h2>
                </div>

                <a th:href="@{{/catalogue}}" class="lien-voir-tout">
                    Voir tout
                </a>
            </div>

{grille_autres}
        </div>
'''

    html = html[:position_fin] + nouvelle_section + html[position_fin:]
    index_file.write_text(html, encoding="utf-8")

# ------------------------------------------------------------
# 3. Ajouter l'espace entre les deux groupes
# ------------------------------------------------------------
css = css_file.read_text(encoding="utf-8")

if "YNS-AUTRES-ANNONCES" not in css:
    css += '''

/* YNS-AUTRES-ANNONCES */
.yns-autres-annonces {
    margin-top: 72px;
    padding-top: 42px;
    border-top: 1px solid rgba(148, 163, 184, 0.35);
}

.yns-autres-titre {
    margin-bottom: 28px;
}

@media (max-width: 700px) {
    .yns-autres-annonces {
        margin-top: 48px;
        padding-top: 32px;
    }
}
/* YNS-AUTRES-ANNONCES-FIN */
'''

    css_file.write_text(css, encoding="utf-8")

print("Modification terminée.")
print("- Les 2 annonces les plus récentes restent en premier.")
print("- Toutes les autres sont affichées sous le titre « Autres annonces ».")
