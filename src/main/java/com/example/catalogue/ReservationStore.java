package com.example.catalogue;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Repository
public class ReservationStore {

    private final JdbcTemplate jdbc;

    public ReservationStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void save(
            String nom,
            String email,
            String telephone,
            String message,
            String articles,
            BigDecimal total
    ) {
        jdbc.update("""
            INSERT INTO reservations
            (nom, email, telephone, message, articles,
             total_indicatif, date_demande, traitee)
            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, FALSE)
            """,
            nom,
            email,
            telephone,
            message,
            articles,
            total
        );
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT * FROM reservations ORDER BY date_demande DESC"
        );
    }

    public void marquerTraitee(Long id) {
        jdbc.update(
            "UPDATE reservations SET traitee = TRUE WHERE id = ?",
            id
        );
    }

    public void delete(Long id) {
        jdbc.update(
            "DELETE FROM reservations WHERE id = ?",
            id
        );
    }
}
