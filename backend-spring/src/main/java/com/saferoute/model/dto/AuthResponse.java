package com.saferoute.model.dto;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class AuthResponse {

    private String token;
    @Builder.Default
    private String type = "Bearer";
    private UUID userId;
    private String name;
    private String email;
    private String emergencyContact;

    public AuthResponse() {
    }

    public AuthResponse(String token, String type, UUID userId, String name, String email, String emergencyContact) {
        this.token = token;
        this.type = type;
        this.userId = userId;
        this.name = name;
        this.email = email;
        this.emergencyContact = emergencyContact;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getEmergencyContact() {
        return emergencyContact;
    }

    public void setEmergencyContact(String emergencyContact) {
        this.emergencyContact = emergencyContact;
    }

    public static AuthResponseBuilder builder() {
        return new AuthResponseBuilder();
    }

    public static class AuthResponseBuilder {
        private String token;
        private String type = "Bearer";
        private UUID userId;
        private String name;
        private String email;
        private String emergencyContact;

        AuthResponseBuilder() {
        }

        public AuthResponseBuilder token(String token) {
            this.token = token;
            return this;
        }

        public AuthResponseBuilder type(String type) {
            this.type = type;
            return this;
        }

        public AuthResponseBuilder userId(UUID userId) {
            this.userId = userId;
            return this;
        }

        public AuthResponseBuilder name(String name) {
            this.name = name;
            return this;
        }

        public AuthResponseBuilder email(String email) {
            this.email = email;
            return this;
        }

        public AuthResponseBuilder emergencyContact(String emergencyContact) {
            this.emergencyContact = emergencyContact;
            return this;
        }

        public AuthResponse build() {
            return new AuthResponse(this.token, this.type, this.userId, this.name, this.email, this.emergencyContact);
        }
    }
}
