package com.example.catalogue;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class NotificationMailService {

    private final JavaMailSender mailSender;
    private final String expediteur;
    private final String destinataire;

    public NotificationMailService(
            JavaMailSender mailSender,
            @Value("${spring.mail.username:}") String expediteur,
            @Value("${app.mail.to:yanisroum01@gmail.com}") String destinataire
    ) {
        this.mailSender = mailSender;
        this.expediteur = expediteur;
        this.destinataire = destinataire;
    }

    public boolean envoyer(String sujet, String contenu) {
        if (expediteur == null || expediteur.isBlank()) {
            System.out.println(
                "MAIL_USERNAME absent : demande enregistrée sans notification email."
            );
            return false;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(expediteur);
            message.setTo(destinataire);
            message.setSubject(sujet);
            message.setText(contenu);

            mailSender.send(message);
            return true;
        } catch (MailException exception) {
            System.err.println(
                "Impossible d'envoyer la notification email : "
                + exception.getMessage()
            );
            return false;
        }
    }
}
