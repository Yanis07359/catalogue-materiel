package com.example.catalogue;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public class AnnonceStore {

    private final JdbcTemplate jdbc;

    public AnnonceStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public long count() {
        Long total = jdbc.queryForObject(
            "SELECT COUNT(*) FROM annonces",
            Long.class
        );

        return total == null ? 0 : total;
    }

    public List<Annonce> findAll() {
        return jdbc.query(
            "SELECT * FROM annonces ORDER BY id DESC",
            (rs, rowNum) -> mapper(rs)
        );
    }

    public Optional<Annonce> findById(Long id) {
        List<Annonce> resultats = jdbc.query(
            "SELECT * FROM annonces WHERE id = ?",
            (rs, rowNum) -> mapper(rs),
            id
        );

        return resultats.stream().findFirst();
    }

    public List<Annonce> findByIds(List<Long> ids) {
        return ids.stream()
                .distinct()
                .map(this::findById)
                .flatMap(Optional::stream)
                .toList();
    }

    public void save(
            Long id,
            String titre,
            String categorie,
            String etat,
            BigDecimal prix,
            String description,
            String statut,
            String lienVinted,
            String lienLeboncoin,
            String photos
    ) {
        if (id == null) {
            jdbc.update("""
                INSERT INTO annonces
                (titre, categorie, etat, prix, description, statut,
                 lien_vinted, lien_leboncoin, photos)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                titre,
                categorie,
                etat,
                prix,
                description,
                statut,
                lienVinted,
                lienLeboncoin,
                photos
            );
        } else {
            jdbc.update("""
                UPDATE annonces
                SET titre = ?,
                    categorie = ?,
                    etat = ?,
                    prix = ?,
                    description = ?,
                    statut = ?,
                    lien_vinted = ?,
                    lien_leboncoin = ?,
                    photos = ?
                WHERE id = ?
                """,
                titre,
                categorie,
                etat,
                prix,
                description,
                statut,
                lienVinted,
                lienLeboncoin,
                photos,
                id
            );
        }
    }

    public void delete(Long id) {
        jdbc.update("DELETE FROM annonces WHERE id = ?", id);
    }

    private Annonce mapper(java.sql.ResultSet rs)
            throws java.sql.SQLException {

        return new Annonce(
            rs.getLong("id"),
            rs.getString("titre"),
            rs.getString("categorie"),
            rs.getString("etat"),
            rs.getBigDecimal("prix"),
            rs.getString("description"),
            rs.getString("statut"),
            rs.getString("lien_vinted"),
            rs.getString("lien_leboncoin"),
            rs.getString("photos")
        );
    }

    public void changerStatut(Long id, String statut) {
        java.util.Set<String> statutsAutorises =
                java.util.Set.of("DISPONIBLE", "RESERVE", "VENDU");

        String nouveauStatut = statut == null
                ? ""
                : statut.trim().toUpperCase();

        if (!statutsAutorises.contains(nouveauStatut)) {
            throw new IllegalArgumentException("Statut non autorisé");
        }

        jdbc.update(
            "UPDATE annonces SET statut = ? WHERE id = ?",
            nouveauStatut,
            id
        );
    }

}
