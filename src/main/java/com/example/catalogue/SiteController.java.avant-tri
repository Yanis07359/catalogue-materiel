package com.example.catalogue;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Controller
public class SiteController {

    private final AnnonceStore annonceStore;
    private final ReservationStore reservationStore;

    public SiteController(
            AnnonceStore annonceStore,
            ReservationStore reservationStore
    ) {
        this.annonceStore = annonceStore;
        this.reservationStore = reservationStore;
    }

    @ModelAttribute
    public void informationsGlobales(
            Model model,
            HttpSession session
    ) {
        model.addAttribute(
            "nombrePanier",
            panierIds(session).size()
        );
    }

    @GetMapping("/")
    public String accueil(Model model) {
        model.addAttribute("annonces", annonceStore.findAll());
        return "index";
    }

    @GetMapping("/catalogue")
    public String catalogue(
            @RequestParam(required = false) String categorie,
            Model model
    ) {
        List<Annonce> annonces = annonceStore.findAll();

        if (categorie != null && !categorie.isBlank()) {
            annonces = annonces.stream()
                    .filter(a -> a.categorie().equalsIgnoreCase(categorie))
                    .toList();
        }

        model.addAttribute("annonces", annonces);
        model.addAttribute("categorie", categorie);

        return "catalogue";
    }

    @GetMapping("/annonce/{id}")
    public String detail(
            @PathVariable Long id,
            Model model
    ) {
        Annonce annonce = annonceStore.findById(id)
                .orElseThrow(() ->
                    new IllegalArgumentException("Annonce introuvable")
                );

        model.addAttribute("annonce", annonce);
        return "annonce";
    }

    @PostMapping("/panier/ajouter/{id}")
    public String ajouterPanier(
            @PathVariable Long id,
            HttpSession session
    ) {
        List<Long> ids = panierIds(session);

        if (annonceStore.findById(id).isPresent() && !ids.contains(id)) {
            ids.add(id);
        }

        return "redirect:/panier";
    }


    @PostMapping("/reservation/directe/{id}")
    public String reservationDirecte(
            @PathVariable Long id,
            HttpSession session
    ) {
        Annonce annonce = annonceStore.findById(id)
                .orElseThrow(() ->
                    new IllegalArgumentException(
                        "Annonce introuvable."
                    )
                );

        if (!"DISPONIBLE".equals(annonce.statut())) {
            return "redirect:/annonce/" + id;
        }

        List<Long> panier = panierIds(session);

        // La réservation directe concerne uniquement cette annonce.
        panier.clear();
        panier.add(id);

        return "redirect:/reservation";
    }

    @PostMapping("/panier/supprimer/{id}")
    public String supprimerPanier(
            @PathVariable Long id,
            HttpSession session
    ) {
        panierIds(session).remove(id);
        return "redirect:/panier";
    }

    @PostMapping("/panier/vider")
    public String viderPanier(HttpSession session) {
        panierIds(session).clear();
        return "redirect:/panier";
    }

    @GetMapping("/panier")
    public String panier(
            HttpSession session,
            Model model
    ) {
        ajouterPanierModele(session, model);
        return "panier";
    }

    @GetMapping("/reservation")
    public String formulaireReservation(
            HttpSession session,
            Model model
    ) {
        if (panierIds(session).isEmpty()) {
            return "redirect:/panier";
        }

        ajouterPanierModele(session, model);
        return "reservation";
    }

    @PostMapping("/reservation")
    public String enregistrerReservation(
            @RequestParam String nom,
            @RequestParam String email,
            @RequestParam(required = false) String telephone,
            @RequestParam(required = false) String message,
            @RequestParam(required = false) String consentement,
            HttpSession session,
            Model model
    ) {
        List<Annonce> annonces =
            annonceStore.findByIds(panierIds(session));

        if (annonces.isEmpty()) {
            return "redirect:/panier";
        }

        if (nom.isBlank() || email.isBlank() || consentement == null) {
            model.addAttribute(
                "erreur",
                "Le nom, l'e-mail et le consentement sont obligatoires."
            );

            ajouterPanierModele(session, model);
            return "reservation";
        }

        String articles = annonces.stream()
                .map(a -> "#" + a.id() + " - " + a.titre())
                .collect(Collectors.joining("\n"));

        BigDecimal total = calculerTotal(annonces);

        reservationStore.save(
            nom,
            email,
            telephone,
            message,
            articles,
            total
        );

        panierIds(session).clear();
        model.addAttribute("nom", nom);

        return "confirmation";
    }

    @GetMapping("/mentions-legales")
    public String mentionsLegales() {
        return "mentions-legales";
    }

    @GetMapping("/confidentialite")
    public String confidentialite() {
        return "confidentialite";
    }

    @GetMapping("/connexion")
    public String connexion() {
        return "login";
    }

    private void ajouterPanierModele(
            HttpSession session,
            Model model
    ) {
        List<Annonce> annonces =
            annonceStore.findByIds(panierIds(session));

        model.addAttribute("annonces", annonces);
        model.addAttribute("total", calculerTotal(annonces));
    }

    private BigDecimal calculerTotal(List<Annonce> annonces) {
        return annonces.stream()
                .map(Annonce::prix)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    @SuppressWarnings("unchecked")
    private List<Long> panierIds(HttpSession session) {
        Object valeur = session.getAttribute("panier");

        if (valeur instanceof List<?>) {
            return (List<Long>) valeur;
        }

        List<Long> panier = new ArrayList<>();
        session.setAttribute("panier", panier);

        return panier;
    }
}
