package com.example.catalogue;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SeoController {

    private static final String BASE_URL =
            "https://catalogue-materiel.onrender.com";

    private final AnnonceStore annonceStore;

    public SeoController(AnnonceStore annonceStore) {
        this.annonceStore = annonceStore;
    }

    @GetMapping(
        value = "/sitemap.xml",
        produces = MediaType.APPLICATION_XML_VALUE
    )
    public String sitemap() {
        StringBuilder xml = new StringBuilder();

        xml.append("""
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            """);

        ajouterUrl(xml, "/");
        ajouterUrl(xml, "/catalogue");
        ajouterUrl(xml, "/recherche-produit");
        ajouterUrl(xml, "/mentions-legales");

        for (Annonce annonce : annonceStore.findAll()) {
            ajouterUrl(xml, "/annonce/" + annonce.id());
        }

        xml.append("</urlset>");
        return xml.toString();
    }

    private void ajouterUrl(StringBuilder xml, String chemin) {
        xml.append("<url><loc>")
           .append(BASE_URL)
           .append(chemin)
           .append("</loc></url>");
    }
}
