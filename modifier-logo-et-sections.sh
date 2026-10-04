#!/usr/bin/env bash
set -e

INDEX="src/main/resources/templates/index.html"
CSS="src/main/resources/static/css/style.css"
SOURCE_LOGO="/home/ubuntu/Downloads/Screenshot From 2026-09-30 23-52-53-1.png"
LOGO="src/main/resources/static/images/logo-yns.png"
FAVICON="src/main/resources/static/favicon.png"
BACKUP="/tmp/yns-logo-sections-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SOURCE_LOGO" ]; then
    echo "ERREUR : image introuvable :"
    echo "$SOURCE_LOGO"
    exit 1
fi

if [ ! -f "$INDEX" ]; then
    echo "ERREUR : fichier index.html introuvable."
    exit 1
fi

mkdir -p "$BACKUP"
mkdir -p "$(dirname "$LOGO")"

cp "$INDEX" "$BACKUP/index.html"
cp "$CSS" "$BACKUP/style.css"

[ -f "$LOGO" ] && cp "$LOGO" "$BACKUP/logo-yns.png"
[ -f "$FAVICON" ] && cp "$FAVICON" "$BACKUP/favicon.png"

cp "$SOURCE_LOGO" "$LOGO"
cp "$SOURCE_LOGO" "$FAVICON"

python3 <<'PYTHON'
from pathlib import Path
import re
import time

index_file = Path("src/main/resources/templates/index.html")
css_file = Path("src/main/resources/static/css/style.css")
templates_dir = Path("src/main/resources/templates")

html = index_file.read_text(encoding="utf-8")


def find_div_block(source, class_name):
    opening = re.search(
        r'<div\b[^>]*class=["\'][^"\']*\b' +
        re.escape(class_name) +
        r'\b[^"\']*["\'][^>]*>',
        source,
        flags=re.IGNORECASE
    )

    if not opening:
        return None

    depth = 0

    for token in re.finditer(
        r'<div\b[^>]*>|</div\s*>',
        source[opening.start():],
        flags=re.IGNORECASE
    ):
        value = token.group(0).lower()

        if value.startswith("<div"):
            depth += 1
        else:
            depth -= 1

        if depth == 0:
            return opening.start(), opening.start() + token.end()

    raise RuntimeError(
        f"Impossible de trouver la fermeture du bloc {class_name}"
    )


# Supprimer la section « Avis vérifiables »
review = find_div_block(html, "yns-extra-panel")

if review:
    start, end = review
    html = html[:start] + html[end:]
    print("Section « Avis vérifiables » supprimée.")
else:
    print("Section « Avis vérifiables » déjà absente.")


# Déplacer « Contact rapide » au début de la section
contact = find_div_block(html, "yns-extra-contact")

if contact:
    start, end = contact
    contact_html = html[start:end].strip()
    html = html[:start] + html[end:]

    container = re.search(
        r'<div\b[^>]*class=["\'][^"\']*\byns-extra-container\b[^"\']*["\'][^>]*>',
        html,
        flags=re.IGNORECASE
    )

    if not container:
        raise RuntimeError("Bloc yns-extra-container introuvable.")

    insertion = container.end()

    html = (
        html[:insertion]
        + "\n\n"
        + contact_html
        + "\n\n"
        + html[insertion:]
    )

    print("Bloc « Contact rapide » déplacé en haut.")
else:
    print("ATTENTION : bloc « Contact rapide » introuvable.")


index_file.write_text(html, encoding="utf-8")


# Forcer le navigateur à charger le nouveau logo et le nouveau favicon
version = str(int(time.time()))

for template in templates_dir.rglob("*.html"):
    content = template.read_text(encoding="utf-8")
    original = content

    content = re.sub(
        r'@\{/images/logo-yns\.png(?:$[^)]*$)?\}',
        f'@{{/images/logo-yns.png(v={version})}}',
        content
    )

    content = re.sub(
        r'(?P<attr>\bsrc=["\'])/images/logo-yns\.png(?:\?[^"\']*)?',
        rf'\g<attr>/images/logo-yns.png?v={version}',
        content
    )

    content = re.sub(
        r'@\{/favicon\.png(?:$[^)]*$)?\}',
        f'@{{/favicon.png(v={version})}}',
        content
    )

    content = re.sub(
        r'(?P<attr>\bhref=["\'])/favicon\.png(?:\?[^"\']*)?',
        rf'\g<attr>/favicon.png?v={version}',
        content
    )

    if content != original:
        template.write_text(content, encoding="utf-8")


# Modifier légèrement la couleur de la barre supérieure
css = css_file.read_text(encoding="utf-8")

css = re.sub(
    r'/\*\s*YNS-HEADER-LOGO-V2-DEBUT\s*\*/.*?'
    r'/\*\s*YNS-HEADER-LOGO-V2-FIN\s*\*/',
    '',
    css,
    flags=re.DOTALL
)

new_css = """
/* YNS-HEADER-LOGO-V2-DEBUT */

/*
 * Fond légèrement bleuté pour distinguer les parties blanches
 * du logo tout en conservant un aspect professionnel.
 */
.header,
.site-header,
header.main-header {
    background: rgba(234, 242, 248, 0.98) !important;
    border-bottom: 1px solid rgba(37, 99, 235, 0.13) !important;
    box-shadow: 0 7px 25px rgba(15, 23, 42, 0.08) !important;
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
}

.yns-logo img,
.site-logo img,
.header-logo img {
    display: block;
    object-fit: contain;
}

/*
 * Contact rapide placé en haut avec un espacement propre.
 */
.yns-extra-container > .yns-extra-contact:first-child {
    margin-top: 0;
    margin-bottom: 45px;
}

@media (max-width: 850px) {
    .yns-extra-container > .yns-extra-contact:first-child {
        margin-bottom: 34px;
    }
}

/* YNS-HEADER-LOGO-V2-FIN */
"""

css_file.write_text(css.rstrip() + "\n\n" + new_css.strip() + "\n",
                    encoding="utf-8")

print("Logo, favicon, sections et barre supérieure modifiés.")
PYTHON

echo
echo "Vérification de la compilation..."
mvn clean package -DskipTests

echo
echo "===================================================="
echo "MODIFICATIONS TERMINÉES"
echo "===================================================="
echo "Sauvegarde disponible dans : $BACKUP"
echo
echo "Pour lancer le site :"
echo "ADMIN_USERNAME=admin ADMIN_PASSWORD='Test123!' mvn spring-boot:run -Dspring-boot.run.profiles=local"
