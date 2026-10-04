#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

STORE="src/main/java/com/example/catalogue/AnnonceStore.java"
ADMIN="src/main/java/com/example/catalogue/AdminController.java"
INDEX="src/main/resources/templates/index.html"
CATALOGUE="src/main/resources/templates/catalogue.html"
ANNONCE="src/main/resources/templates/annonce.html"
ADMIN_HTML="src/main/resources/templates/admin/annonces.html"
CSS="src/main/resources/static/css/style.css"

for fichier in "$STORE" "$ADMIN" "$INDEX" "$ADMIN_HTML" "$CSS"; do
    if [ ! -f "$fichier" ]; then
        echo "ERREUR : fichier introuvable : $fichier"
        exit 1
    fi
done

BACKUP="/tmp/yns-equipements-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp "$STORE" "$BACKUP/"
cp "$ADMIN" "$BACKUP/"
cp "$INDEX" "$BACKUP/"
cp "$ADMIN_HTML" "$BACKUP/"
cp "$CSS" "$BACKUP/"

[ -f "$CATALOGUE" ] && cp "$CATALOGUE" "$BACKUP/"
[ -f "$ANNONCE" ] && cp "$ANNONCE" "$BACKUP/"

echo "Sauvegarde créée dans : $BACKUP"

python3 <<'PYTHON'
from pathlib import Path
import re

store_file = Path("src/main/java/com/example/catalogue/AnnonceStore.java")
admin_file = Path("src/main/java/com/example/catalogue/AdminController.java")
index_file = Path("src/main/resources/templates/index.html")
catalogue_file = Path("src/main/resources/templates/catalogue.html")
annonce_file = Path("src/main/resources/templates/annonce.html")
admin_html_file = Path("src/main/resources/templates/admin/annonces.html")
css_file = Path("src/main/resources/static/css/style.css")

# ------------------------------------------------------------
# 1. Méthode de modification du statut dans AnnonceStore
# ------------------------------------------------------------

store = store_file.read_text(encoding="utf-8")

if "void changerStatut(" not in store:
    method = r'''
    public void changerStatut(Long id, String statut) {
        if (id == null) {
            throw new IllegalArgumentException("Identifiant d'annonce absent.");
        }

        if (statut == null ||
            !java.util.List.of("DISPONIBLE", "RESERVE", "VENDU").contains(statut)) {
            throw new IllegalArgumentException("Statut d'annonce invalide.");
        }

        int lignesModifiees = jdbcTemplate.update(
            "UPDATE annonces SET statut = ? WHERE id = ?",
            statut,
            id
        );

        if (lignesModifiees == 0) {
            throw new IllegalArgumentException("Annonce introuvable : " + id);
        }
    }
'''
    position = store.rfind("\n}")
    if position == -1:
        raise RuntimeError("Impossible de modifier AnnonceStore.java")

    store = store[:position] + "\n" + method + store[position:]
    store_file.write_text(store, encoding="utf-8")

# ------------------------------------------------------------
# 2. Route d'administration pour changer le statut
# ------------------------------------------------------------

admin = admin_file.read_text(encoding="utf-8")

if '"/annonces/{id}/statut"' not in admin:
    route = r'''
    @PostMapping("/annonces/{id}/statut")
    public String changerStatut(
            @PathVariable Long id,
            @RequestParam String statut,
            RedirectAttributes redirectAttributes) {

        try {
            annonceStore.changerStatut(id, statut);
            redirectAttributes.addFlashAttribute(
                "succes",
                "Le statut de l'annonce a été mis à jour."
            );
        } catch (Exception exception) {
            redirectAttributes.addFlashAttribute(
                "erreur",
                "Impossible de modifier le statut : " + exception.getMessage()
            );
        }

        return "redirect:/admin/annonces";
    }

'''
    markers = [
        '@PostMapping("/annonces/{id}/supprimer")',
        '@GetMapping("/annonces/{id}/supprimer")'
    ]

    inserted = False

    for marker in markers:
        position = admin.find(marker)
        if position != -1:
            line_start = admin.rfind("\n", 0, position) + 1
            admin = admin[:line_start] + route + admin[line_start:]
            inserted = True
            break

    if not inserted:
        position = admin.rfind("\n}")
        if position == -1:
            raise RuntimeError("Impossible de modifier AdminController.java")

        admin = admin[:position] + "\n" + route + admin[position:]

    admin_file.write_text(admin, encoding="utf-8")

# ------------------------------------------------------------
# 3. Sélecteur de statut dans la page d'administration
# ------------------------------------------------------------

admin_html = admin_html_file.read_text(encoding="utf-8")

if 'class="admin-status-form"' not in admin_html:
    status_form = r'''<td>
    <form class="admin-status-form"
          method="post"
          th:action="@{/admin/annonces/{id}/statut(id=${annonce.id})}">

        <select name="statut"
                class="admin-status-select"
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

        <button type="submit" class="admin-status-button">
            Mettre à jour
        </button>
    </form>
</td>'''

    patterns = [
        r'<td\s+th:text="\$\{annonce\.statut\}"\s*>\s*</td>',
        r'<td[^>]*>\s*<span[^>]*th:text="\$\{annonce\.statut\}"[^>]*>.*?</span>\s*</td>'
    ]

    replaced = False

    for pattern in patterns:
        updated, count = re.subn(
            pattern,
            status_form,
            admin_html,
            count=1,
            flags=re.DOTALL
        )

        if count:
            admin_html = updated
            replaced = True
            break

    if not replaced:
        print("AVERTISSEMENT : la cellule du statut dans admin/annonces.html n'a pas été trouvée.")
        print("Les autres modifications seront tout de même appliquées.")

    admin_html_file.write_text(admin_html, encoding="utf-8")

# ------------------------------------------------------------
# 4. Traduction propre des statuts sur les pages publiques
# ------------------------------------------------------------

status_expression = (
    "${annonce.statut == 'DISPONIBLE' ? 'Disponible' : "
    "(annonce.statut == 'RESERVE' ? 'Réservé' : 'Vendu')}"
)

for template_file in [index_file, catalogue_file, annonce_file]:
    if not template_file.exists():
        continue

    content = template_file.read_text(encoding="utf-8")
    content = content.replace(
        'th:text="${annonce.statut}"',
        f'th:text="{status_expression}"'
    )
    template_file.write_text(content, encoding="utf-8")

# ------------------------------------------------------------
# 5. Sections confiance, évaluations et contact rapide
# ------------------------------------------------------------

index = index_file.read_text(encoding="utf-8")

if 'id="confiance-contact"' not in index:
    section = r'''
<!-- YNS-CONFIANCE-DEBUT -->
<section id="confiance-contact" class="yns-trust-section">
    <div class="yns-section-container">

        <div class="yns-section-heading">
            <span class="yns-section-kicker">Nos engagements</span>
            <h2>Achetez en toute confiance</h2>
            <p>
                Chaque produit est sélectionné avec attention afin de proposer
                du matériel recherché, fiable et offrant un excellent rapport
                qualité-prix.
            </p>
        </div>

        <div class="yns-trust-grid">
            <article class="yns-trust-card">
                <span class="yns-card-number">01</span>
                <h3>Produits vérifiés</h3>
                <p>
                    Les produits sont contrôlés et décrits avec transparence
                    avant leur publication sur le site.
                </p>
            </article>

            <article class="yns-trust-card">
                <span class="yns-card-number">02</span>
                <h3>Paiements sécurisés</h3>
                <p>
                    Les paiements sont réalisés uniquement sur des plateformes
                    reconnues comme Vinted ou Leboncoin.
                </p>
            </article>

            <article class="yns-trust-card">
                <span class="yns-card-number">03</span>
                <h3>Livraison ou remise en main propre</h3>
                <p>
                    La livraison est disponible selon l'annonce. Une remise en
                    main propre peut également être organisée lorsque cela est possible.
                </p>
            </article>
        </div>

        <div class="yns-reviews-panel">
            <div class="yns-reviews-content">
                <span class="yns-section-kicker">Avis et évaluations</span>
                <h2>Consultez nos profils officiels</h2>
                <p>
                    Retrouvez les évaluations laissées après des transactions
                    réellement effectuées sur nos profils Vinted et Leboncoin.
                    Les témoignages individuels ne sont publiés sur ce site
                    qu'avec l'accord des personnes concernées.
                </p>
            </div>

            <div class="yns-review-links">
                <a class="yns-platform-button yns-vinted"
                   href="https://www.vinted.fr/member/295112160"
                   target="_blank"
                   rel="noopener noreferrer">
                    Voir les évaluations Vinted
                </a>

                <a class="yns-platform-button yns-leboncoin"
                   href="https://www.leboncoin.fr/profile/ff32c61b-0f71-467c-88d9-50efcc6a5fc8"
                   target="_blank"
                   rel="noopener noreferrer">
                    Voir les évaluations Leboncoin
                </a>
            </div>
        </div>

        <div class="yns-contact-panel">
            <div>
                <span class="yns-section-kicker">Une question ?</span>
                <h2>Contactez-nous rapidement</h2>
                <p>
                    Besoin d'informations supplémentaires sur un produit,
                    sa disponibilité ou sa livraison ? Nous sommes à votre écoute.
                </p>
            </div>

            <div class="yns-contact-buttons">
                <a class="yns-contact-button yns-contact-email"
                   href="mailto:yanisroum01@gmail.com?subject=Question%20concernant%20une%20annonce%20YNS%20Equipements">
                    Envoyer un email
                </a>

                <a class="yns-contact-button yns-contact-instagram"
                   href="https://www.instagram.com/yns_equipements/"
                   target="_blank"
                   rel="noopener noreferrer">
                    Contacter sur Instagram
                </a>
            </div>
        </div>

    </div>
</section>
<!-- YNS-CONFIANCE-FIN -->

'''

    markers = [
        "<!-- PRESENTATION-V4 -->",
        '<section id="presentation"',
        '<section class="presentation',
        "</main>"
    ]

    inserted = False

    for marker in markers:
        position = index.find(marker)
        if position != -1:
            index = index[:position] + section + index[position:]
            inserted = True
            break

    if not inserted:
        position = index.lower().find("</body>")
        if position == -1:
            raise RuntimeError("Impossible d'insérer les sections dans index.html")

        index = index[:position] + section + index[position:]

    index_file.write_text(index, encoding="utf-8")

# ------------------------------------------------------------
# 6. CSS responsive et correction du message de paiement
# ------------------------------------------------------------

css = css_file.read_text(encoding="utf-8")

start_marker = "/* YNS-AMELIORATIONS-DEBUT */"
end_marker = "/* YNS-AMELIORATIONS-FIN */"

if start_marker in css and end_marker in css:
    start = css.find(start_marker)
    end = css.find(end_marker) + len(end_marker)
    css = css[:start] + css[end:]

new_css = r'''

/* YNS-AMELIORATIONS-DEBUT */

/*
 * Le message d'information reste dans le footer.
 * Il ne doit jamais suivre le défilement de la page.
 */
.avertissement,
.payment-warning,
.payment-notice,
.legal-warning,
.site-warning {
    position: static !important;
    inset: auto !important;
    top: auto !important;
    right: auto !important;
    bottom: auto !important;
    left: auto !important;
    transform: none !important;
    z-index: auto !important;
}

/* Section confiance */
.yns-trust-section {
    padding: 78px 20px;
    background:
        radial-gradient(circle at top right, rgba(32, 119, 255, 0.10), transparent 34%),
        linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
}

.yns-section-container {
    width: min(1180px, 100%);
    margin: 0 auto;
}

.yns-section-heading {
    max-width: 720px;
    margin: 0 auto 42px;
    text-align: center;
}

.yns-section-kicker {
    display: inline-block;
    margin-bottom: 10px;
    color: #2563eb;
    font-size: 0.78rem;
    font-weight: 800;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.yns-section-heading h2,
.yns-reviews-panel h2,
.yns-contact-panel h2 {
    margin: 0 0 14px;
    color: #0f172a;
    font-size: clamp(1.7rem, 4vw, 2.6rem);
    line-height: 1.15;
}

.yns-section-heading p,
.yns-reviews-panel p,
.yns-contact-panel p {
    margin: 0;
    color: #64748b;
    font-size: 1rem;
    line-height: 1.75;
}

.yns-trust-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 20px;
}

.yns-trust-card {
    position: relative;
    min-height: 220px;
    padding: 30px;
    overflow: hidden;
    border: 1px solid #e2e8f0;
    border-radius: 22px;
    background: #ffffff;
    box-shadow: 0 18px 45px rgba(15, 23, 42, 0.07);
}

.yns-card-number {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 46px;
    height: 46px;
    margin-bottom: 24px;
    border-radius: 14px;
    color: #ffffff;
    background: linear-gradient(135deg, #2563eb, #0f172a);
    font-size: 0.82rem;
    font-weight: 800;
}

.yns-trust-card h3 {
    margin: 0 0 12px;
    color: #0f172a;
    font-size: 1.18rem;
}

.yns-trust-card p {
    margin: 0;
    color: #64748b;
    line-height: 1.7;
}

/* Avis et profils officiels */
.yns-reviews-panel {
    display: grid;
    grid-template-columns: minmax(0, 1.5fr) minmax(240px, 0.7fr);
    gap: 36px;
    align-items: center;
    margin-top: 28px;
    padding: 38px;
    border: 1px solid #dbeafe;
    border-radius: 24px;
    background: #eff6ff;
}

.yns-review-links,
.yns-contact-buttons {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.yns-platform-button,
.yns-contact-button {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 50px;
    padding: 12px 20px;
    border-radius: 13px;
    text-align: center;
    text-decoration: none;
    font-weight: 750;
    transition:
        transform 160ms ease,
        box-shadow 160ms ease,
        opacity 160ms ease;
}

.yns-platform-button:hover,
.yns-contact-button:hover {
    transform: translateY(-2px);
    opacity: 0.94;
}

.yns-vinted {
    color: #ffffff;
    background: #007782;
    box-shadow: 0 10px 25px rgba(0, 119, 130, 0.22);
}

.yns-leboncoin {
    color: #ffffff;
    background: #ff6e14;
    box-shadow: 0 10px 25px rgba(255, 110, 20, 0.22);
}

/* Contact rapide */
.yns-contact-panel {
    display: grid;
    grid-template-columns: minmax(0, 1.5fr) minmax(240px, 0.7fr);
    gap: 36px;
    align-items: center;
    margin-top: 28px;
    padding: 38px;
    border-radius: 24px;
    color: #ffffff;
    background:
        radial-gradient(circle at top right, rgba(59, 130, 246, 0.5), transparent 35%),
        #0f172a;
    box-shadow: 0 24px 55px rgba(15, 23, 42, 0.18);
}

.yns-contact-panel h2,
.yns-contact-panel p {
    color: #ffffff;
}

.yns-contact-panel p {
    opacity: 0.78;
}

.yns-contact-panel .yns-section-kicker {
    color: #93c5fd;
}

.yns-contact-email {
    color: #0f172a;
    background: #ffffff;
}

.yns-contact-instagram {
    color: #ffffff;
    background: linear-gradient(135deg, #833ab4, #fd1d1d, #fcb045);
}

/* Administration des statuts */
.admin-status-form {
    display: flex;
    align-items: center;
    gap: 8px;
    min-width: 220px;
}

.admin-status-select {
    min-height: 38px;
    padding: 7px 30px 7px 10px;
    border: 1px solid #cbd5e1;
    border-radius: 9px;
    color: #0f172a;
    background-color: #ffffff;
    font: inherit;
    font-size: 0.86rem;
    font-weight: 700;
}

.admin-status-select.status-disponible {
    border-color: #86efac;
    background-color: #f0fdf4;
}

.admin-status-select.status-reserve {
    border-color: #fde68a;
    background-color: #fffbeb;
}

.admin-status-select.status-vendu {
    border-color: #cbd5e1;
    background-color: #f1f5f9;
}

.admin-status-button {
    min-height: 38px;
    padding: 8px 12px;
    border: 0;
    border-radius: 9px;
    color: #ffffff;
    background: #2563eb;
    cursor: pointer;
    font: inherit;
    font-size: 0.8rem;
    font-weight: 750;
}

.admin-status-button:hover {
    background: #1d4ed8;
}

@media (max-width: 850px) {
    .yns-trust-section {
        padding: 56px 16px;
    }

    .yns-trust-grid {
        grid-template-columns: 1fr;
    }

    .yns-trust-card {
        min-height: auto;
    }

    .yns-reviews-panel,
    .yns-contact-panel {
        grid-template-columns: 1fr;
        gap: 26px;
        padding: 28px 22px;
    }

    .admin-status-form {
        flex-direction: column;
        align-items: stretch;
        min-width: 150px;
    }
}

@media (max-width: 480px) {
    .yns-section-heading {
        margin-bottom: 30px;
    }

    .yns-trust-card {
        padding: 24px;
        border-radius: 18px;
    }

    .yns-reviews-panel,
    .yns-contact-panel {
        border-radius: 19px;
    }

    .yns-platform-button,
    .yns-contact-button {
        width: 100%;
        min-height: 48px;
        padding: 11px 14px;
        font-size: 0.9rem;
    }
}

/* YNS-AMELIORATIONS-FIN */
'''

css_file.write_text(css.rstrip() + new_css + "\n", encoding="utf-8")

print("Toutes les modifications ont été appliquées.")
PYTHON

echo
echo "Vérification de la compilation..."
mvn clean package -DskipTests

echo
echo "=============================================================="
echo "MODIFICATIONS TERMINÉES"
echo "=============================================================="
echo "Sauvegarde : $BACKUP"
echo
echo "Pour lancer le site localement :"
echo "ADMIN_USERNAME=admin ADMIN_PASSWORD='Test123!' mvn spring-boot:run"
echo
echo "Puis ouvre : http://localhost:8080"
echo "Administration : http://localhost:8080/admin"
