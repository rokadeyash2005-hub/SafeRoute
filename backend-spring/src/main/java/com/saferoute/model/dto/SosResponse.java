package com.saferoute.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SosResponse {

    private UUID alertId;
    private String dispatchStatus;
    private String emergencyContact;
    private String message;
    private Double latitude;
    private Double longitude;
    private String liveTrackingUrl;
    private LocalDateTime dispatchedAt;
}
