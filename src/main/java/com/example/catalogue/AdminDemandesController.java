package com.example.catalogue;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/admin/demandes")
public class AdminDemandesController {

    private final DemandeClientStore demandeStore;

    public AdminDemandesController(DemandeClientStore demandeStore) {
        this.demandeStore = demandeStore;
    }

    @GetMapping
    public String demandes(Model model) {
        model.addAttribute("demandes", demandeStore.findAll());
        return "admin/demandes";
    }

    @PostMapping("/{id}/statut")
    public String changerStatut(
            @PathVariable Long id,
            @RequestParam String statut,
            RedirectAttributes redirectAttributes
    ) {
        demandeStore.changerStatut(id, statut);
        redirectAttributes.addFlashAttribute(
            "succes",
            "Le statut de la demande a été modifié."
        );
        return "redirect:/admin/demandes";
    }

    @PostMapping("/{id}/supprimer")
    public String supprimer(
            @PathVariable Long id,
            RedirectAttributes redirectAttributes
    ) {
        demandeStore.supprimer(id);
        redirectAttributes.addFlashAttribute(
            "succes",
            "La demande a été supprimée."
        );
        return "redirect:/admin/demandes";
    }
}
