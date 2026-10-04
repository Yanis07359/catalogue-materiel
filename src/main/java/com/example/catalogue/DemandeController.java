package com.example.catalogue;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;

@Controller
public class DemandeController {

    private final AnnonceStore annonceStore;
    private final DemandeClientStore demandeStore;
    private final NotificationMailService mailService;

    public DemandeController(
            AnnonceStore annonceStore,
            DemandeClientStore demandeStore,
            NotificationMailService mailService
    ) {
        this.annonceStore = annonceStore;
        this.demandeStore = demandeStore;
        this.mailService = mailService;
    }

    @GetMapping("/recherche-produit")
    public String formulaireRecherche(Model model) {
        model.addAttribute("nombrePanier", 0);
        return "demande-produit";
    }

    @PostMapping("/recherche-produit")
    public String enregistrerRecherche(
            @RequestParam String nom,
            @RequestParam String email,
            @RequestParam(required = false) String telephone,
            @RequestParam String produitRecherche,
            @RequestParam(required = false) String details,
            @RequestParam(required = false) String budget,
            Model model
    ) {
        model.addAttribute("nombrePanier", 0);

        BigDecimal montantBudget = convertirMontant(budget);

        if (nom.isBlank() || email.isBlank() || produitRecherche.isBlank()) {
            model.addAttribute(
                "erreur",
                "Veuillez compléter les champs obligatoires."
            );
            return "demande-produit";
        }

        demandeStore.enregistrerRecherche(
            nom.trim(),
            email.trim(),
            telephone,
            produitRecherche.trim(),
            details,
            montantBudget
        );

        String contenu = """
            Nouvelle recherche de produit sur YNS Equipements

            Nom : %s
            Email : %s
            Téléphone : %s
            Produit recherché : %s
            Budget souhaité : %s €
            
            Détails :
            %s
            """.formatted(
                nom,
                email,
                valeurOuNonRenseigne(telephone),
                produitRecherche,
                montantBudget == null ? "Non renseigné" : montantBudget,
                valeurOuNonRenseigne(details)
            );

        boolean emailEnvoye = mailService.envoyer(
            "Nouvelle recherche de produit - YNS Equipements",
            contenu
        );

        model.addAttribute(
            "titreConfirmation",
            "Votre demande a bien été envoyée"
        );
        model.addAttribute(
            "messageConfirmation",
            "Nous allons rechercher le produit correspondant à vos besoins et à votre budget."
        );
        model.addAttribute("emailEnvoye", emailEnvoye);

        return "demande-confirmation";
    }

    @GetMapping("/annonce/{id}/offre")
    public String formulaireOffre(
            @PathVariable Long id,
            Model model
    ) {
        Annonce annonce = annonceStore.findById(id)
            .orElseThrow(() ->
                new IllegalArgumentException("Annonce introuvable")
            );

        model.addAttribute("annonce", annonce);
        model.addAttribute("nombrePanier", 0);

        return "offre-prix";
    }

    @PostMapping("/annonce/{id}/offre")
    public String enregistrerOffre(
            @PathVariable Long id,
            @RequestParam String nom,
            @RequestParam String email,
            @RequestParam(required = false) String telephone,
            @RequestParam String prixPropose,
            @RequestParam(required = false) String message,
            Model model
    ) {
        Annonce annonce = annonceStore.findById(id)
            .orElseThrow(() ->
                new IllegalArgumentException("Annonce introuvable")
            );

        model.addAttribute("annonce", annonce);
        model.addAttribute("nombrePanier", 0);

        BigDecimal montant = convertirMontant(prixPropose);

        if (nom.isBlank() || email.isBlank()) {
            model.addAttribute(
                "erreur",
                "Veuillez renseigner votre nom et votre email."
            );
            return "offre-prix";
        }

        if (montant == null || montant.compareTo(BigDecimal.ZERO) <= 0) {
            model.addAttribute(
                "erreur",
                "Veuillez saisir un prix valide."
            );
            return "offre-prix";
        }

        demandeStore.enregistrerOffre(
            annonce.id(),
            annonce.titre(),
            nom.trim(),
            email.trim(),
            telephone,
            montant,
            message
        );

        String contenu = """
            Nouvelle offre de prix sur YNS Equipements

            Annonce : %s
            Identifiant : %s
            Prix affiché : %s €
            Prix proposé : %s €

            Nom : %s
            Email : %s
            Téléphone : %s

            Message :
            %s
            """.formatted(
                annonce.titre(),
                annonce.id(),
                annonce.prix(),
                montant,
                nom,
                email,
                valeurOuNonRenseigne(telephone),
                valeurOuNonRenseigne(message)
            );

        boolean emailEnvoye = mailService.envoyer(
            "Nouvelle offre pour " + annonce.titre(),
            contenu
        );

        model.addAttribute(
            "titreConfirmation",
            "Votre offre a bien été envoyée"
        );
        model.addAttribute(
            "messageConfirmation",
            "Votre proposition sera étudiée. Une réponse vous sera envoyée par email."
        );
        model.addAttribute("emailEnvoye", emailEnvoye);

        return "demande-confirmation";
    }

    private BigDecimal convertirMontant(String valeur) {
        if (valeur == null || valeur.isBlank()) {
            return null;
        }

        try {
            return new BigDecimal(
                valeur.trim()
                    .replace("€", "")
                    .replace(" ", "")
                    .replace(",", ".")
            );
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private String valeurOuNonRenseigne(String valeur) {
        if (valeur == null || valeur.isBlank()) {
            return "Non renseigné";
        }
        return valeur.trim();
    }
}
