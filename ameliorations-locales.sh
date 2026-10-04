#!/usr/bin/env bash
set -e

INDEX="src/main/resources/templates/index.html"
CSS="src/main/resources/static/css/style.css"
BACKUP="/tmp/yns-local-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
cp "$INDEX" "$BACKUP/index.html"
cp "$CSS" "$BACKUP/style.css"

python3 <<'PYTHON'
from pathlib import Path
import re

index_file = Path("src/main/resources/templates/index.html")
css_file = Path("src/main/resources/static/css/style.css")

html = index_file.read_text(encoding="utf-8")

# Supprime une ancienne version éventuelle pour éviter les doublons.
html = re.sub(
    r'\s*<!-- YNS-INFOS-DEBUT -->.*?<!-- YNS-INFOS-FIN -->\s*',
    '\n',
    html,
    flags=re.DOTALL
)

section = '''
<!-- YNS-INFOS-DEBUT -->
<section class="yns-extra-section" id="confiance">
    <div class="yns-extra-container">

        <div class="yns-extra-heading">
            <span class="yns-extra-kicker">Nos engagements</span>
            <h2>Achetez en toute confiance</h2>
            <p>
                Chaque produit est sélectionné avec attention afin de proposer
                du matériel recherché, fiable et offrant un excellent rapport
                qualité-prix.
            </p>
        </div>

        <div class="yns-extra-grid">
            <article class="yns-extra-card">
                <div class="yns-extra-icon">✓</div>
                <h3>Produits vérifiés</h3>
                <p>
                    Le fonctionnement et l'état du matériel sont vérifiés avant
                    la publication de chaque annonce.
                </p>
            </article>

            <article class="yns-extra-card">
                <div class="yns-extra-icon">€</div>
                <h3>Paiement sécurisé</h3>
                <p>
                    Les paiements sont réalisés uniquement sur Vinted,
                    Leboncoin ou lors d'une remise en main propre.
                </p>
            </article>

            <article class="yns-extra-card">
                <div class="yns-extra-icon">★</div>
                <h3>Qualité-prix</h3>
                <p>
                    Nous privilégions du matériel utile et demandé, choisi pour
                    sa qualité, son usage et la cohérence de son prix.
                </p>
            </article>
        </div>

        <div class="yns-extra-panel">
            <div>
                <span class="yns-extra-kicker">Avis vérifiables</span>
                <h2>Consultez nos profils officiels</h2>
                <p>
                    Retrouvez les évaluations issues de transactions réellement
                    réalisées directement sur nos profils Vinted et Leboncoin.
                </p>
            </div>

            <div class="yns-extra-buttons">
                <a class="yns-extra-button yns-vinted"
                   href="https://www.vinted.fr/member/295112160"
                   target="_blank" rel="noopener noreferrer">
                    Voir les avis Vinted
                </a>

                <a class="yns-extra-button yns-leboncoin"
                   href="https://www.leboncoin.fr/profile/ff32c61b-0f71-467c-88d9-50efcc6a5fc8"
                   target="_blank" rel="noopener noreferrer">
                    Voir le profil Leboncoin
                </a>
            </div>
        </div>

        <div class="yns-extra-contact">
            <div>
                <span class="yns-extra-kicker">Contact rapide</span>
                <h2>Une question sur un produit ?</h2>
                <p>
                    Contactez YNS Equipements par email ou Instagram pour
                    obtenir des informations complémentaires.
                </p>
            </div>

            <div class="yns-extra-buttons">
                <a class="yns-extra-button yns-email"
                   href="mailto:yanisroum01@gmail.com">
                    Envoyer un email
                </a>

                <a class="yns-extra-button yns-instagram"
                   href="https://www.instagram.com/yns_equipements/"
                   target="_blank" rel="noopener noreferrer">
                    Contacter sur Instagram
                </a>
            </div>
        </div>

    </div>
</section>
<!-- YNS-INFOS-FIN -->
'''

# Insère avant la présentation existante.
markers = [
    "<!-- PRESENTATION-V4 -->",
    '<section id="a-propos"',
    "</main>"
]

inserted = False

for marker in markers:
    position = html.find(marker)
    if position != -1:
        html = html[:position] + section + "\n" + html[position:]
        inserted = True
        break

if not inserted:
    html = html.replace("</body>", section + "\n</body>")

index_file.write_text(html, encoding="utf-8")

css = css_file.read_text(encoding="utf-8")

css = re.sub(
    r'/\* YNS-INFOS-CSS-DEBUT \*/.*?/\* YNS-INFOS-CSS-FIN \*/',
    '',
    css,
    flags=re.DOTALL
)

new_css = r'''

/* YNS-INFOS-CSS-DEBUT */

/* L'avertissement ne reste plus bloqué pendant le défilement. */
.site-warning,
.warning-banner,
.payment-warning {
    position: static !important;
    inset: auto !important;
    transform: none !important;
    z-index: auto !important;
}

.yns-extra-section {
    padding: 72px 20px;
    background:
        radial-gradient(circle at top right, rgba(37, 99, 235, 0.09), transparent 35%),
        linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
}

.yns-extra-container {
    width: min(1160px, 100%);
    margin: 0 auto;
}

.yns-extra-heading {
    max-width: 760px;
    margin: 0 auto 38px;
    text-align: center;
}

.yns-extra-kicker {
    display: inline-block;
    margin-bottom: 10px;
    color: #2563eb;
    font-size: 0.78rem;
    font-weight: 800;
    letter-spacing: 0.13em;
    text-transform: uppercase;
}

.yns-extra-heading h2,
.yns-extra-panel h2,
.yns-extra-contact h2 {
    margin: 0 0 14px;
    color: #0f172a;
    font-size: clamp(1.65rem, 4vw, 2.5rem);
    line-height: 1.15;
}

.yns-extra-heading p,
.yns-extra-panel p,
.yns-extra-contact p {
    margin: 0;
    color: #64748b;
    line-height: 1.75;
}

.yns-extra-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 20px;
}

.yns-extra-card {
    padding: 28px;
    border: 1px solid #e2e8f0;
    border-radius: 22px;
    background: #ffffff;
    box-shadow: 0 18px 42px rgba(15, 23, 42, 0.07);
}

.yns-extra-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 44px;
    height: 44px;
    margin-bottom: 21px;
    border-radius: 13px;
    color: #ffffff;
    background: linear-gradient(135deg, #2563eb, #0f172a);
    font-size: 1rem;
    font-weight: 900;
}

.yns-extra-card h3 {
    margin: 0 0 11px;
    color: #0f172a;
    font-size: 1.12rem;
}

.yns-extra-card p {
    margin: 0;
    color: #64748b;
    line-height: 1.7;
}

.yns-extra-panel,
.yns-extra-contact {
    display: grid;
    grid-template-columns: minmax(0, 1.5fr) minmax(230px, 0.7fr);
    gap: 34px;
    align-items: center;
    margin-top: 28px;
    padding: 36px;
    border-radius: 24px;
}

.yns-extra-panel {
    border: 1px solid #dbeafe;
    background: #eff6ff;
}

.yns-extra-contact {
    color: #ffffff;
    background:
        radial-gradient(circle at top right, rgba(59, 130, 246, 0.48), transparent 38%),
        #0f172a;
    box-shadow: 0 22px 50px rgba(15, 23, 42, 0.16);
}

.yns-extra-contact h2,
.yns-extra-contact p {
    color: #ffffff;
}

.yns-extra-contact p {
    opacity: 0.8;
}

.yns-extra-contact .yns-extra-kicker {
    color: #93c5fd;
}

.yns-extra-buttons {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.yns-extra-button {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 50px;
    padding: 12px 18px;
    border-radius: 13px;
    text-align: center;
    text-decoration: none;
    font-weight: 750;
    transition: transform 160ms ease, opacity 160ms ease;
}

.yns-extra-button:hover {
    transform: translateY(-2px);
    opacity: 0.93;
}

.yns-vinted {
    color: #ffffff;
    background: #007782;
}

.yns-leboncoin {
    color: #ffffff;
    background: #ff6e14;
}

.yns-email {
    color: #0f172a;
    background: #ffffff;
}

.yns-instagram {
    color: #ffffff;
    background: linear-gradient(135deg, #833ab4, #fd1d1d, #fcb045);
}

@media (max-width: 850px) {
    .yns-extra-section {
        padding: 54px 16px;
    }

    .yns-extra-grid {
        grid-template-columns: 1fr;
    }

    .yns-extra-panel,
    .yns-extra-contact {
        grid-template-columns: 1fr;
        gap: 25px;
        padding: 27px 22px;
    }
}

@media (max-width: 480px) {
    .yns-extra-card {
        padding: 23px;
        border-radius: 18px;
    }

    .yns-extra-panel,
    .yns-extra-contact {
        border-radius: 19px;
    }

    .yns-extra-button {
        width: 100%;
        min-height: 48px;
        padding: 11px 13px;
        font-size: 0.9rem;
    }
}

/* YNS-INFOS-CSS-FIN */
'''

css_file.write_text(css.rstrip() + new_css + "\n", encoding="utf-8")

print("Améliorations locales ajoutées avec succès.")
PYTHON

echo "Vérification de la compilation..."
mvn clean package -DskipTests

echo
echo "Terminé. Aucune modification n'a été envoyée sur GitHub."
echo "Sauvegarde disponible dans : $BACKUP"
