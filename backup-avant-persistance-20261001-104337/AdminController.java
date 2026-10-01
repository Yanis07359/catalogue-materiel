package com.example.catalogue;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Controller
@RequestMapping("/admin")
public class AdminController {

    private final AnnonceStore annonceStore;
    private final ReservationStore reservationStore;

    public AdminController(
            AnnonceStore annonceStore,
            ReservationStore reservationStore
    ) {
        this.annonceStore = annonceStore;
        this.reservationStore = reservationStore;
    }

    @GetMapping
    public String accueilAdmin() {
        return "redirect:/admin/annonces";
    }

    @GetMapping("/annonces")
    public String annonces(Model model) {
        model.addAttribute("annonces", annonceStore.findAll());
        return "admin/annonces";
    }

    @GetMapping("/annonces/nouvelle")
    public String nouvelleAnnonce(Model model) {
        model.addAttribute("annonce", null);
        return "admin/annonce-form";
    }

    @GetMapping("/annonces/{id}/modifier")
    public String modifierAnnonce(
            @PathVariable Long id,
            Model model
    ) {
        Annonce annonce = annonceStore.findById(id)
                .orElseThrow(() ->
                    new IllegalArgumentException("Annonce introuvable")
                );

        model.addAttribute("annonce", annonce);
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
            @RequestParam(required = false) MultipartFile[] images
    ) throws IOException {

        List<String> photos = new ArrayList<>();

        if (photosActuelles != null && !photosActuelles.isBlank()) {
            photos.addAll(
                photosActuelles.lines()
                    .map(String::trim)
                    .filter(s -> !s.isBlank())
                    .toList()
            );
        }

        if (photosUrls != null && !photosUrls.isBlank()) {
            photos.addAll(
                photosUrls.lines()
                    .map(String::trim)
                    .filter(s -> !s.isBlank())
                    .toList()
            );
        }

        if (images != null) {
            Path dossier = Path.of("uploads");
            Files.createDirectories(dossier);

            for (MultipartFile image : images) {
                if (image == null || image.isEmpty()) {
                    continue;
                }

                String original = image.getOriginalFilename();
                String extension = "";

                if (original != null && original.contains(".")) {
                    extension = original.substring(
                        original.lastIndexOf(".")
                    );
                }

                String nomFichier =
                    UUID.randomUUID() + extension.toLowerCase();

                Files.copy(
                    image.getInputStream(),
                    dossier.resolve(nomFichier),
                    StandardCopyOption.REPLACE_EXISTING
                );

                photos.add("/uploads/" + nomFichier);
            }
        }

        annonceStore.save(
            id,
            titre,
            categorie,
            etat,
            prix,
            description,
            statut,
            lienVinted == null ? "" : lienVinted,
            lienLeboncoin == null ? "" : lienLeboncoin,
            String.join("\n", photos)
        );

        return "redirect:/admin/annonces";
    }

    @PostMapping("/annonces/{id}/supprimer")
    public String supprimerAnnonce(@PathVariable Long id) {
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
    public String traiterReservation(@PathVariable Long id) {
        reservationStore.marquerTraitee(id);
        return "redirect:/admin/reservations";
    }

    @PostMapping("/reservations/{id}/supprimer")
    public String supprimerReservation(@PathVariable Long id) {
        reservationStore.delete(id);
        return "redirect:/admin/reservations";
    }
}
