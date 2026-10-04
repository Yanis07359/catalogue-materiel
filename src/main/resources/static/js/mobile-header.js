(() => {
    const header = document.querySelector(".yns-site-header, .header");

    if (!header) {
        return;
    }

    const mobileScreen = window.matchMedia("(max-width: 650px)");

    let previousPosition = Math.max(window.scrollY, 0);
    let animationEnCours = false;

    function mettreAJourLaBarre() {
        const positionActuelle = Math.max(window.scrollY, 0);

        if (!mobileScreen.matches) {
            header.classList.remove("yns-mobile-header-hidden");
            previousPosition = positionActuelle;
            animationEnCours = false;
            return;
        }

        /*
         * En haut de la page :
         * toujours afficher la barre.
         */
        if (positionActuelle <= 5) {
            header.classList.remove("yns-mobile-header-hidden");
        }

        /*
         * Dès que l'utilisateur remonte :
         * faire revenir immédiatement la barre.
         */
        else if (positionActuelle < previousPosition) {
            header.classList.remove("yns-mobile-header-hidden");
        }

        /*
         * Quand l'utilisateur descend :
         * cacher la barre après avoir dépassé sa hauteur.
         */
        else if (
            positionActuelle > previousPosition &&
            positionActuelle > header.offsetHeight
        ) {
            header.classList.add("yns-mobile-header-hidden");
        }

        previousPosition = positionActuelle;
        animationEnCours = false;
    }

    window.addEventListener("scroll", () => {
        if (!animationEnCours) {
            window.requestAnimationFrame(mettreAJourLaBarre);
            animationEnCours = true;
        }
    }, { passive: true });

    function verifierTailleEcran() {
        if (!mobileScreen.matches) {
            header.classList.remove("yns-mobile-header-hidden");
        }

        previousPosition = Math.max(window.scrollY, 0);
    }

    if (mobileScreen.addEventListener) {
        mobileScreen.addEventListener("change", verifierTailleEcran);
    } else {
        mobileScreen.addListener(verifierTailleEcran);
    }
})();
