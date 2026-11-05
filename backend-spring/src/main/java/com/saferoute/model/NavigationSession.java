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
@Table(name = "navigation_sessions")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavigationSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "source_lat", nullable = false)
    private Double sourceLat;

    @Column(name = "source_lng", nullable = false)
    private Double sourceLng;

    @Column(name = "dest_lat", nullable = false)
    private Double destLat;

    @Column(name = "dest_lng", nullable = false)
    private Double destLng;

    @Column(name = "selected_route_summary")
    private String selectedRouteSummary;

    @Column(name = "composite_risk_score")
    private Double compositeRiskScore;

    @Column(name = "safety_rating")
    private Double safetyRating;

    @Column(name = "total_distance_meters")
    private Double totalDistanceMeters;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
