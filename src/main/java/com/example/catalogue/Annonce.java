package com.example.catalogue;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

public record Annonce(
        Long id,
        String titre,
        String categorie,
        String etat,
        BigDecimal prix,
        String description,
        String statut,
        String lienVinted,
        String lienLeboncoin,
        String lienSubito,
        String photos
) {
    public List<String> listePhotos() {
        if (photos == null || photos.isBlank()) {
            return List.of(
                "https://placehold.co/1000x700?text=Photo+indisponible"
            );
        }

        return Arrays.stream(photos.split("\\R"))
                .map(String::trim)
                .filter(photo -> !photo.isBlank())
                .toList();
    }

    public String photoPrincipale() {
        return listePhotos().getFirst();
    }

    public boolean aVinted() {
        return lienVinted != null && !lienVinted.isBlank();
    }

    public boolean aLeboncoin() {
        return lienLeboncoin != null && !lienLeboncoin.isBlank();
    }

    public boolean aSubito() {
        return lienSubito != null && !lienSubito.isBlank();
    }

    public String statutCss() {
        return statut == null ? "" : statut.toLowerCase();
    }
}
