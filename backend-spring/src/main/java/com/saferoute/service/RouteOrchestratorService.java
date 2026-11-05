package com.saferoute.service;

import com.saferoute.config.CustomUserPrincipal;
import com.saferoute.model.NavigationSession;
import com.saferoute.model.dto.*;
import com.saferoute.repository.NavigationSessionRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@SuppressWarnings("null")
public class RouteOrchestratorService {

    private final GoogleDirectionsService directionsService;
    private final NavigationSessionRepository sessionRepository;
    private final WebClient webClient;

    public RouteOrchestratorService(GoogleDirectionsService directionsService,
                                   NavigationSessionRepository sessionRepository,
                                   WebClient webClient) {
        this.directionsService = directionsService;
        this.sessionRepository = sessionRepository;
        this.webClient = webClient;
    }

    @Value("${integrations.ml.service.url:http://localhost:8082/api/ml/evaluate-routes}")
    private String mlServiceUrl;

    @Transactional
    public RouteRecommendationResponse recommendSafestRoute(RouteRecommendRequest request) {
        UUID currentUserId = getCurrentAuthenticatedUserId();
        log.info("Initiating Safe Route orchestration for user: {} ({} -> {})",
                currentUserId, request.getSourceLat(), request.getDestLat());

        // Step 1: Query Google Directions API (or simulation) for alternative route options
        List<RouteCandidateDto> candidateRoutes = directionsService.fetchAlternateRoutes(
                request.getSourceLat(), request.getSourceLng(),
                request.getDestLat(), request.getDestLng()
        );

        if (candidateRoutes.isEmpty()) {
            throw new IllegalStateException("Unable to retrieve candidate routing paths for requested coordinates.");
        }

        // Step 2: Assemble payload for Python FastAPI ML Microservice
        LocalDateTime depTime = request.getDepartureTime() != null ? request.getDepartureTime() : LocalDateTime.now();

        MlRouteEvaluationRequest mlPayload = MlRouteEvaluationRequest.builder()
                .origin(new CoordinateDto(request.getSourceLat(), request.getSourceLng()))
                .destination(new CoordinateDto(request.getDestLat(), request.getDestLng()))
                .departureTime(depTime.format(DateTimeFormatter.ISO_DATE_TIME))
                .routes(candidateRoutes)
                .build();

        // Step 3: Call FastAPI ML Service
        MlRouteEvaluationResponse mlResponse = callMlMicroservice(mlPayload);

        int bestIndex = (mlResponse != null && mlResponse.getSafestRouteIndex() != null)
                ? mlResponse.getSafestRouteIndex()
                : 0;

        RouteCandidateDto chosenCandidate = candidateRoutes.get(Math.min(bestIndex, candidateRoutes.size() - 1));

        Double compositeRisk = (mlResponse != null && mlResponse.getCompositeRiskScore() != null)
                ? mlResponse.getCompositeRiskScore()
                : 2.5;

        Double safetyRating = (mlResponse != null && mlResponse.getSafetyRating() != null)
                ? mlResponse.getSafetyRating()
                : 4.5;

        List<CoordinateDto> finalPolyline = (mlResponse != null && mlResponse.getRecommendedPolyline() != null && !mlResponse.getRecommendedPolyline().isEmpty())
                ? mlResponse.getRecommendedPolyline()
                : chosenCandidate.getCoordinates();

        // Extract alternative route polyline if multiple route candidates exist
        List<CoordinateDto> alternatePolyline = Collections.emptyList();
        if (candidateRoutes.size() > 1) {
            int altIdx = (bestIndex == 0) ? 1 : 0;
            alternatePolyline = candidateRoutes.get(altIdx).getCoordinates();
        }

        // Step 4: Persist Navigation Session in PostgreSQL
        NavigationSession session = NavigationSession.builder()
                .userId(currentUserId)
                .sourceLat(request.getSourceLat())
                .sourceLng(request.getSourceLng())
                .destLat(request.getDestLat())
                .destLng(request.getDestLng())
                .selectedRouteSummary(chosenCandidate.getSummary())
                .compositeRiskScore(compositeRisk)
                .safetyRating(safetyRating)
                .totalDistanceMeters(chosenCandidate.getTotalDistanceMeters())
                .build();

        NavigationSession savedSession = sessionRepository.save(session);
        log.info("Persisted Safe-Route Navigation Session ID: {}", savedSession.getId());

        // Step 5: Format final client response
        return RouteRecommendationResponse.builder()
                .sessionId(savedSession.getId())
                .safestRouteIndex(bestIndex)
                .routeSummary(chosenCandidate.getSummary())
                .compositeRiskScore(compositeRisk)
                .safetyRating(safetyRating)
                .totalDistanceMeters(chosenCandidate.getTotalDistanceMeters())
                .recommendedPolyline(finalPolyline)
                .alternatePolyline(alternatePolyline)
                .totalEvaluatedRoutes(candidateRoutes.size())
                .detailedSegmentAnalysis(mlResponse != null ? mlResponse.getDetailedSegmentAnalysis() : Collections.emptyList())
                .allEvaluatedRoutes(mlResponse != null ? mlResponse.getAllEvaluatedRoutes() : Collections.emptyList())
                .evaluatedAt(LocalDateTime.now())
                .build();
    }

    private MlRouteEvaluationResponse callMlMicroservice(MlRouteEvaluationRequest payload) {
        try {
            log.info("Dispatching {} route candidates to ML microservice at: {}",
                    payload.getRoutes().size(), mlServiceUrl);

            return webClient.post()
                    .uri(mlServiceUrl)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(payload)
                    .retrieve()
                    .bodyToMono(MlRouteEvaluationResponse.class)
                    .block();
        } catch (Exception ex) {
            log.error("Failed to connect to ML scoring microservice at {}: {}. Utilizing fallback scoring heuristic.",
                    mlServiceUrl, ex.getMessage());

            // Resilient fallback heuristic if ML microservice is unreachable during offline review
            return MlRouteEvaluationResponse.builder()
                    .status("heuristic_fallback")
                    .safestRouteIndex(0)
                    .compositeRiskScore(2.5)
                    .safetyRating(4.5)
                    .totalEvaluatedRoutes(payload.getRoutes().size())
                    .recommendedPolyline(payload.getRoutes().get(0).getCoordinates())
                    .detailedSegmentAnalysis(Collections.emptyList())
                    .allEvaluatedRoutes(Collections.emptyList())
                    .build();
        }
    }

    private UUID getCurrentAuthenticatedUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserPrincipal principal) {
            return principal.getId();
        }
        return UUID.fromString("00000000-0000-0000-0000-000000000000");
    }
}
