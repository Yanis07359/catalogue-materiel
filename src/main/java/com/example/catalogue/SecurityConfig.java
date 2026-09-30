package com.example.catalogue;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService utilisateurs(
            PasswordEncoder encoder,
            @Value("${site.admin.username}") String username,
            @Value("${site.admin.password}") String password
    ) {
        UserDetails admin = User.builder()
                .username(username)
                .password(encoder.encode(password))
                .roles("ADMIN")
                .build();

        return new InMemoryUserDetailsManager(admin);
    }

    @Bean
    SecurityFilterChain securite(HttpSecurity http)
            throws Exception {

        http.authorizeHttpRequests(auth -> auth
            .requestMatchers(
                "/admin/**"
            ).hasRole("ADMIN")
            .anyRequest().permitAll()
        );

        http.formLogin(form -> form
            .loginPage("/connexion")
            .loginProcessingUrl("/connexion")
            .defaultSuccessUrl("/admin", true)
            .failureUrl("/connexion?error")
            .permitAll()
        );

        http.logout(logout -> logout
            .logoutUrl("/deconnexion")
            .logoutSuccessUrl("/")
        );

        return http.build();
    }
}
