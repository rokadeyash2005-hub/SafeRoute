package com.saferoute.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sos_alerts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SosAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(length = 500)
    private String message;

    @Column(name = "emergency_contact", nullable = false, length = 30)
    private String emergencyContact;

    @Column(name = "dispatch_status", nullable = false, length = 50)
    private String dispatchStatus;

    @CreationTimestamp
    @Column(name = "dispatched_at", nullable = false, updatable = false)
    private LocalDateTime dispatchedAt;
}
