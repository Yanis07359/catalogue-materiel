if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
        navigator.serviceWorker.register("/service-worker.js")
            .then(registration => {
                console.log("PWA YNS activée :", registration.scope);
            })
            .catch(error => {
                console.error("Erreur PWA :", error);
            });
    });
}
