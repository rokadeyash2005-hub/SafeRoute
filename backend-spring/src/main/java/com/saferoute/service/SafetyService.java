package com.saferoute.service;

import com.saferoute.config.CustomUserPrincipal;
import com.saferoute.model.SosAlert;
import com.saferoute.model.User;
import com.saferoute.model.dto.SosRequest;
import com.saferoute.model.dto.SosResponse;
import com.saferoute.repository.SosAlertRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@SuppressWarnings("null")
public class SafetyService {

    private final SosAlertRepository sosAlertRepository;

    public SafetyService(SosAlertRepository sosAlertRepository) {
        this.sosAlertRepository = sosAlertRepository;
    }

    @Transactional
    public SosResponse triggerEmergencySos(SosRequest request) {
        CustomUserPrincipal principal = getCurrentAuthenticatedPrincipal();
        User user = principal.getUser();

        String mapsTrackingUrl = String.format("https://www.google.com/maps?q=%f,%f",
                request.getLatitude(), request.getLongitude());

        String alertMessage = (request.getMessage() != null && !request.getMessage().isBlank())
                ? request.getMessage().trim()
                : "EMERGENCY: I feel unsafe. Here is my live GPS location.";

        log.warn("🚨 CRITICAL SOS DISPATCHED for user [{}] (ID: {}). Target Emergency Contact: {}",
                user.getName(), user.getId(), user.getEmergencyContact());
        log.warn("🚨 Emergency Live GPS Coordinates: ({}, {}). Maps link: {}",
                request.getLatitude(), request.getLongitude(), mapsTrackingUrl);

        // Persist Alert Record in PostgreSQL
        SosAlert sosAlert = SosAlert.builder()
                .userId(user.getId())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .message(alertMessage)
                .emergencyContact(user.getEmergencyContact())
                .dispatchStatus("DISPATCHED_TO_EMERGENCY_CONTACT")
                .build();

        SosAlert savedAlert = sosAlertRepository.save(sosAlert);

        // In a production deployment, this invokes Twilio SMS Gateway / Firebase Push Notification
        log.info("Simulated SMS dispatch completed to {}: '{} - Live URL: {}'",
                user.getEmergencyContact(), alertMessage, mapsTrackingUrl);

        return SosResponse.builder()
                .alertId(savedAlert.getId())
                .dispatchStatus("DISPATCHED_SUCCESSFULLY")
                .emergencyContact(user.getEmergencyContact())
                .message(alertMessage)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .liveTrackingUrl(mapsTrackingUrl)
                .dispatchedAt(LocalDateTime.now())
                .build();
    }

    private CustomUserPrincipal getCurrentAuthenticatedPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserPrincipal principal) {
            return principal;
        }
        throw new IllegalStateException("Authentication context does not contain a valid user principal.");
    }
}
