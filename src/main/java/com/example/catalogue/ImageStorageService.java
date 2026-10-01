package com.example.catalogue;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class ImageStorageService {

    private static final long TAILLE_MAXIMALE = 10L * 1024L * 1024L;

    private static final Set<String> TYPES_ACCEPTES = Set.of(
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/gif",
        "image/heic",
        "image/heif"
    );

    private final Cloudinary cloudinary;

    public ImageStorageService() {
        String cloudinaryUrl = System.getenv("CLOUDINARY_URL");

        if (cloudinaryUrl == null || cloudinaryUrl.isBlank()) {
            cloudinary = null;

            System.out.println(
                "CLOUDINARY_URL absente : " +
                "les images seront enregistrées localement."
            );
        } else {
            cloudinary = new Cloudinary(cloudinaryUrl);
            cloudinary.config.secure = true;

            System.out.println(
                "Cloudinary est configuré pour le stockage des images."
            );
        }
    }

    public String enregistrer(MultipartFile image) throws IOException {
        verifierImage(image);

        if (cloudinary != null) {
            return envoyerVersCloudinary(image);
        }

        return enregistrerLocalement(image);
    }

    public boolean utiliseCloudinary() {
        return cloudinary != null;
    }

    private void verifierImage(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new IllegalArgumentException(
                "Le fichier image est vide."
            );
        }

        if (image.getSize() > TAILLE_MAXIMALE) {
            throw new IllegalArgumentException(
                "L'image dépasse la limite de 10 Mo."
            );
        }

        String contentType = image.getContentType();

        if (contentType == null ||
                (!contentType.startsWith("image/") &&
                 !TYPES_ACCEPTES.contains(contentType))) {

            throw new IllegalArgumentException(
                "Le fichier sélectionné n'est pas une image valide."
            );
        }
    }

    private String envoyerVersCloudinary(
            MultipartFile image
    ) throws IOException {

        Map<?, ?> resultat = cloudinary.uploader().upload(
            image.getBytes(),
            ObjectUtils.asMap(
                "folder", "yns-equipements",
                "resource_type", "image",
                "use_filename", true,
                "unique_filename", true
            )
        );

        Object secureUrl = resultat.get("secure_url");

        if (secureUrl == null) {
            throw new IOException(
                "Cloudinary n'a retourné aucune URL d'image."
            );
        }

        return secureUrl.toString();
    }

    private String enregistrerLocalement(
            MultipartFile image
    ) throws IOException {

        Path dossier = Path.of("uploads");
        Files.createDirectories(dossier);

        String extension = trouverExtension(
            image.getOriginalFilename()
        );

        String nomFichier =
            UUID.randomUUID() + extension;

        Files.copy(
            image.getInputStream(),
            dossier.resolve(nomFichier),
            StandardCopyOption.REPLACE_EXISTING
        );

        return "/uploads/" + nomFichier;
    }

    private String trouverExtension(String nomOriginal) {
        if (nomOriginal == null || !nomOriginal.contains(".")) {
            return ".jpg";
        }

        String extension = nomOriginal.substring(
            nomOriginal.lastIndexOf(".")
        ).toLowerCase();

        if (extension.length() > 10) {
            return ".jpg";
        }

        return extension;
    }
}
