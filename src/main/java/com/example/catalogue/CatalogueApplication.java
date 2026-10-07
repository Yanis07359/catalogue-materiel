package com.example.catalogue;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.math.BigDecimal;

@SpringBootApplication
public class CatalogueApplication {

    public static void main(String[] args) {
        SpringApplication.run(CatalogueApplication.class, args);
    }

    @Bean
    CommandLineRunner initialiserDonnees(AnnonceStore store) {
        return args -> {
            if (store.count() == 0) {
                store.save(
                    null,
                    "Caméra Sony professionnelle",
                    "Audiovisuel",
                    "Très bon état",
                    new BigDecimal("250.00"),
                    """
                    Caméra Sony en très bon état.

                    Elle est vendue avec une batterie, un chargeur
                    et un sac de transport.
                    """,
                    "DISPONIBLE",
                    "https://www.vinted.fr/",
                    "https://www.leboncoin.fr/",
                    "",
                    """
                    https://images.unsplash.com/photo-1516035069371-29a1b244cc32
                    https://images.unsplash.com/photo-1502982720700-bfff97f2ecac
                    """
                );

                store.save(
                    null,
                    "Carte graphique gaming",
                    "Pièce PC",
                    "Bon état",
                    new BigDecimal("180.00"),
                    """
                    Carte graphique testée et fonctionnelle.

                    Idéale pour un ordinateur gaming ou une station
                    de travail.
                    """,
                    "DISPONIBLE",
                    "",
                    "https://www.leboncoin.fr/",
                    "",
                    """
                    https://images.unsplash.com/photo-1591488320449-011701bb6704
                    """
                );

                store.save(
                    null,
                    "Microphone de studio",
                    "Audiovisuel",
                    "Excellent état",
                    new BigDecimal("95.00"),
                    """
                    Microphone de studio avec support.

                    Convient pour l'enregistrement de voix,
                    les podcasts et le streaming.
                    """,
                    "DISPONIBLE",
                    "https://www.vinted.fr/",
                    "",
                    "",
                    """
                    https://images.unsplash.com/photo-1590602847861-f357a9332bbc
                    """
                );
            }
        };
    }
}
