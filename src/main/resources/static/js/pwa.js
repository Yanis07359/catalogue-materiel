(() => {
    "use strict";

    let installationEvent = null;

    const isInstalled = () =>
        window.matchMedia("(display-mode: standalone)").matches ||
        window.navigator.standalone === true;

    const isIOS = () =>
        /iphone|ipad|ipod/i.test(window.navigator.userAgent);

    const updateButtons = () => {
        document.querySelectorAll(".yns-install-app-button").forEach(button => {
            button.classList.toggle("is-visible", !isInstalled());
        });
    };

    window.addEventListener("beforeinstallprompt", event => {
        event.preventDefault();
        installationEvent = event;
        updateButtons();
    });

    document.addEventListener("DOMContentLoaded", updateButtons);

    document.addEventListener("click", async event => {
        const button = event.target.closest(".yns-install-app-button");

        if (!button) {
            return;
        }

        if (isInstalled()) {
            alert("L’application est déjà installée sur cet appareil.");
            updateButtons();
            return;
        }

        if (installationEvent) {
            installationEvent.prompt();

            const result = await installationEvent.userChoice;

            installationEvent = null;

            if (result.outcome === "accepted") {
                document.querySelectorAll(".yns-install-app-button")
                    .forEach(item => item.classList.remove("is-visible"));
            }

            return;
        }

        if (isIOS()) {
            alert(
                "Sur iPhone ou iPad : appuyez sur le bouton Partager, puis choisissez « Sur l’écran d’accueil »."
            );
            return;
        }

        alert(
            "Si la fenêtre d’installation ne s’affiche pas, ouvrez le menu de votre navigateur puis choisissez « Installer l’application » ou « Ajouter à l’écran d’accueil »."
        );
    });

    window.addEventListener("appinstalled", () => {
        installationEvent = null;

        document.querySelectorAll(".yns-install-app-button")
            .forEach(button => button.classList.remove("is-visible"));
    });

    if ("serviceWorker" in navigator) {
        window.addEventListener("load", () => {
            navigator.serviceWorker.register("/service-worker.js")
                .catch(error => {
                    console.warn("Service Worker non enregistré :", error);
                });
        });
    }
})();
