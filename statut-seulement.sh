#!/usr/bin/env bash
set -e

BACKUP="/tmp/yns-equipements-20261003-235138"

echo "1. Restauration de la version avant les dernières améliorations..."

cp "$BACKUP/AnnonceStore.java" \
   src/main/java/com/example/catalogue/AnnonceStore.java

cp "$BACKUP/AdminController.java" \
   src/main/java/com/example/catalogue/AdminController.java

cp "$BACKUP/index.html" \
   src/main/resources/templates/index.html

cp "$BACKUP/annonces.html" \
   src/main/resources/templates/admin/annonces.html

cp "$BACKUP/catalogue.html" \
   src/main/resources/templates/catalogue.html

cp "$BACKUP/annonce.html" \
   src/main/resources/templates/annonce.html

cp "$BACKUP/style.css" \
   src/main/resources/static/css/style.css

echo "2. Ajout de la modification rapide du statut..."

python3 <<'PYTHON'
from pathlib import Path

# ============================================================
# AnnonceStore.java
# ============================================================

store_file = Path(
    "src/main/java/com/example/catalogue/AnnonceStore.java"
)
store = store_file.read_text(encoding="utf-8")

method = '''
    public void changerStatut(Long id, String statut) {
        java.util.Set<String> statutsAutorises =
                java.util.Set.of("DISPONIBLE", "RESERVE", "VENDU");

        String nouveauStatut = statut == null
                ? ""
                : statut.trim().toUpperCase();

        if (!statutsAutorises.contains(nouveauStatut)) {
            throw new IllegalArgumentException("Statut non autorisé");
        }

        jdbc.update(
            "UPDATE annonces SET statut = ? WHERE id = ?",
            nouveauStatut,
            id
        );
    }

'''

if "void changerStatut(Long id, String statut)" not in store:
    position = store.rfind("}")
    store = store[:position] + method + store[position:]

store_file.write_text(store, encoding="utf-8")


# ============================================================
# AdminController.java
# ============================================================

controller_file = Path(
    "src/main/java/com/example/catalogue/AdminController.java"
)
controller = controller_file.read_text(encoding="utf-8")

route = '''
    @PostMapping("/annonces/{id}/statut")
    public String changerStatut(
            @PathVariable Long id,
            @RequestParam String statut) {

        annonceStore.changerStatut(id, statut);
        return "redirect:/admin/annonces";
    }

'''

if '@PostMapping("/annonces/{id}/statut")' not in controller:
    marker = '    @PostMapping("/annonces/{id}/supprimer")'

    if marker in controller:
        controller = controller.replace(marker, route + marker, 1)
    else:
        position = controller.rfind("}")
        controller = controller[:position] + route + controller[position:]

controller_file.write_text(controller, encoding="utf-8")


# ============================================================
# Page d'administration
# ============================================================

html_file = Path(
    "src/main/resources/templates/admin/annonces.html"
)
html = html_file.read_text(encoding="utf-8")

old = '<td th:text="${annonce.statut}"></td>'

new = '''<td>
    <form class="admin-status-form"
          method="post"
          th:action="@{/admin/annonces/{id}/statut(id=${annonce.id})}">

        <select class="admin-status-select"
                name="statut"
                th:classappend="${annonce.statut == 'DISPONIBLE'} ? ' status-disponible' :
                               (${annonce.statut == 'RESERVE'} ? ' status-reserve' : ' status-vendu')">

            <option value="DISPONIBLE"
                    th:selected="${annonce.statut == 'DISPONIBLE'}">
                Disponible
            </option>

            <option value="RESERVE"
                    th:selected="${annonce.statut == 'RESERVE'}">
                Réservé
            </option>

            <option value="VENDU"
                    th:selected="${annonce.statut == 'VENDU'}">
                Vendu
            </option>
        </select>

        <button class="admin-status-button" type="submit">
            Modifier
        </button>
    </form>
</td>'''

if old not in html:
    raise SystemExit(
        "Impossible de trouver la cellule du statut dans admin/annonces.html"
    )

html = html.replace(old, new, 1)
html_file.write_text(html, encoding="utf-8")


# ============================================================
# Style du bouton
# ============================================================

css_file = Path("src/main/resources/static/css/style.css")
css = css_file.read_text(encoding="utf-8")

css_status = r'''

/* Modification rapide du statut dans l'administration */
.admin-status-form {
    display: flex;
    align-items: center;
    gap: 8px;
}

.admin-status-select {
    min-height: 40px;
    padding: 8px 32px 8px 12px;
    border: 1px solid #cbd5e1;
    border-radius: 9px;
    color: #0f172a;
    background: #ffffff;
    font: inherit;
    font-size: 0.88rem;
    font-weight: 700;
}

.admin-status-select.status-disponible {
    border-color: #86efac;
    color: #166534;
    background: #f0fdf4;
}

.admin-status-select.status-reserve {
    border-color: #fde68a;
    color: #92400e;
    background: #fffbeb;
}

.admin-status-select.status-vendu {
    border-color: #cbd5e1;
    color: #475569;
    background: #f1f5f9;
}

.admin-status-button {
    min-height: 40px;
    padding: 8px 14px;
    border: 0;
    border-radius: 9px;
    color: #ffffff;
    background: #2563eb;
    cursor: pointer;
    font: inherit;
    font-size: 0.84rem;
    font-weight: 750;
}

.admin-status-button:hover {
    background: #1d4ed8;
}

@media (max-width: 700px) {
    .admin-status-form {
        min-width: 140px;
        flex-direction: column;
        align-items: stretch;
    }

    .admin-status-select,
    .admin-status-button {
        width: 100%;
    }
}
'''

if "Modification rapide du statut dans l'administration" not in css:
    css = css.rstrip() + css_status + "\n"

css_file.write_text(css, encoding="utf-8")

print("Modification du statut ajoutée avec succès.")
PYTHON

echo "3. Vérification du projet..."

mvn clean package -DskipTests

echo
echo "======================================================"
echo "TERMINÉ : seule la gestion des statuts a été ajoutée."
echo "======================================================"
