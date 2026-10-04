package com.example.catalogue;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Repository
public class DemandeClientStore {

    private static final Set<String> STATUTS_AUTORISES = Set.of(
        "NOUVELLE",
        "CONTACTEE",
        "ACCEPTEE",
        "REFUSEE"
    );

    private final JdbcTemplate jdbcTemplate;

    public DemandeClientStore(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void enregistrerRecherche(
            String nom,
            String email,
            String telephone,
            String produitRecherche,
            String details,
            BigDecimal budget
    ) {
        jdbcTemplate.update("""
            INSERT INTO demandes_client (
                type_demande,
                nom,
                email,
                telephone,
                produit_recherche,
                details,
                budget,
                statut,
                date_demande
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 'NOUVELLE', ?)
            """,
            "RECHERCHE_PRODUIT",
            nom,
            email,
            nettoyer(telephone),
            produitRecherche,
            nettoyer(details),
            budget,
            Timestamp.valueOf(LocalDateTime.now())
        );
    }

    public void enregistrerOffre(
            Long annonceId,
            String annonceTitre,
            String nom,
            String email,
            String telephone,
            BigDecimal prixPropose,
            String message
    ) {
        jdbcTemplate.update("""
            INSERT INTO demandes_client (
                type_demande,
                annonce_id,
                annonce_titre,
                nom,
                email,
                telephone,
                prix_propose,
                message,
                statut,
                date_demande
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'NOUVELLE', ?)
            """,
            "OFFRE_PRIX",
            annonceId,
            annonceTitre,
            nom,
            email,
            nettoyer(telephone),
            prixPropose,
            nettoyer(message),
            Timestamp.valueOf(LocalDateTime.now())
        );
    }

    public List<Map<String, Object>> findAll() {
        return jdbcTemplate.queryForList("""
            SELECT *
            FROM demandes_client
            ORDER BY date_demande DESC, id DESC
            """);
    }

    public void changerStatut(Long id, String statut) {
        if (statut == null || !STATUTS_AUTORISES.contains(statut)) {
            throw new IllegalArgumentException("Statut non autorisé");
        }

        jdbcTemplate.update("""
            UPDATE demandes_client
            SET statut = ?
            WHERE id = ?
            """, statut, id);
    }

    public void supprimer(Long id) {
        jdbcTemplate.update(
            "DELETE FROM demandes_client WHERE id = ?",
            id
        );
    }

    private String nettoyer(String valeur) {
        if (valeur == null || valeur.isBlank()) {
            return null;
        }
        return valeur.trim();
    }
}
