package com.example.catalogue;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/admin")
public class AdminController {

    private final AnnonceStore annonceStore;
    private final ReservationStore reservationStore;
    private final ImageStorageService imageStorageService;

    public AdminController(
            AnnonceStore annonceStore,
            ReservationStore reservationStore,
            ImageStorageService imageStorageService
    ) {
        this.annonceStore = annonceStore;
        this.reservationStore = reservationStore;
        this.imageStorageService = imageStorageService;
    }

    @GetMapping
    public String accueilAdmin() {
        return "redirect:/admin/annonces";
    }

    @GetMapping("/annonces")
    public String annonces(Model model) {
        model.addAttribute(
            "annonces",
            annonceStore.findAll()
        );

        return "admin/annonces";
    }

    @GetMapping("/annonces/nouvelle")
    public String nouvelleAnnonce(Model model) {
        model.addAttribute("annonce", null);
        model.addAttribute(
            "cloudinaryActif",
            imageStorageService.utiliseCloudinary()
        );

        return "admin/annonce-form";
    }

    @GetMapping("/annonces/{id}/modifier")
    public String modifierAnnonce(
            @PathVariable Long id,
            Model model
    ) {
        Annonce annonce = annonceStore.findById(id)
                .orElseThrow(() ->
                    new IllegalArgumentException(
                        "Annonce introuvable."
                    )
                );

        model.addAttribute("annonce", annonce);
        model.addAttribute(
            "cloudinaryActif",
            imageStorageService.utiliseCloudinary()
        );

        return "admin/annonce-form";
    }

    @PostMapping("/annonces/enregistrer")
    public String enregistrerAnnonce(
            @RequestParam(required = false) Long id,
            @RequestParam String titre,
            @RequestParam String categorie,
            @RequestParam String etat,
            @RequestParam BigDecimal prix,
            @RequestParam String description,
            @RequestParam String statut,
            @RequestParam(required = false) String lienVinted,
            @RequestParam(required = false) String lienLeboncoin,
            @RequestParam(required = false) String photosUrls,
            @RequestParam(required = false) String photosActuelles,
            @RequestParam(required = false) MultipartFile[] images,
            Model model
    ) {
        try {
            List<String> photos = new ArrayList<>();

            ajouterUrls(
                photos,
                photosActuelles
            );

            ajouterUrls(
                photos,
                photosUrls
            );

            if (images != null) {
                for (MultipartFile image : images) {
                    if (image == null || image.isEmpty()) {
                        continue;
                    }

                    String imageUrl =
                        imageStorageService.enregistrer(image);

                    photos.add(imageUrl);
                }
            }

            annonceStore.save(
                id,
                titre.trim(),
                categorie,
                etat.trim(),
                prix,
                description.trim(),
                statut,
                valeurOuVide(lienVinted),
                valeurOuVide(lienLeboncoin),
                String.join("\n", photos)
            );

            return "redirect:/admin/annonces";

        } catch (IOException |
                 IllegalArgumentException exception) {

            Annonce annonce = new Annonce(
                id,
                titre,
                categorie,
                etat,
                prix,
                description,
                statut,
                valeurOuVide(lienVinted),
                valeurOuVide(lienLeboncoin),
                valeurOuVide(photosActuelles)
            );

            model.addAttribute("annonce", annonce);
            model.addAttribute(
                "erreur",
                exception.getMessage()
            );
            model.addAttribute(
                "cloudinaryActif",
                imageStorageService.utiliseCloudinary()
            );

            return "admin/annonce-form";
        }
    }

    @PostMapping("/annonces/{id}/supprimer")
    public String supprimerAnnonce(
            @PathVariable Long id
    ) {
        annonceStore.delete(id);
        return "redirect:/admin/annonces";
    }

    @GetMapping("/reservations")
    public String reservations(Model model) {
        model.addAttribute(
            "reservations",
            reservationStore.findAll()
        );

        return "admin/reservations";
    }

    @PostMapping("/reservations/{id}/traiter")
    public String traiterReservation(
            @PathVariable Long id
    ) {
        reservationStore.marquerTraitee(id);
        return "redirect:/admin/reservations";
    }

    @PostMapping("/reservations/{id}/supprimer")
    public String supprimerReservation(
            @PathVariable Long id
    ) {
        reservationStore.delete(id);
        return "redirect:/admin/reservations";
    }

    private void ajouterUrls(
            List<String> photos,
            String texte
    ) {
        if (texte == null || texte.isBlank()) {
            return;
        }

        texte.lines()
            .map(String::trim)
            .filter(url -> !url.isBlank())
            .filter(url ->
                url.startsWith("https://") ||
                url.startsWith("http://") ||
                url.startsWith("/uploads/")
            )
            .forEach(photos::add);
    }

    private String valeurOuVide(String valeur) {
        return valeur == null ? "" : valeur.trim();
    }
}
