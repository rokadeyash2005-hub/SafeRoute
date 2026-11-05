package com.saferoute.controller;

import com.saferoute.model.dto.RouteRecommendRequest;
import com.saferoute.model.dto.RouteRecommendationResponse;
import com.saferoute.service.RouteOrchestratorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/routes")
@RequiredArgsConstructor
public class RouteController {

    private final RouteOrchestratorService routeOrchestratorService;

    @PostMapping("/recommend")
    public ResponseEntity<RouteRecommendationResponse> recommendSafestRoute(
            @Valid @RequestBody RouteRecommendRequest request) {
        RouteRecommendationResponse response = routeOrchestratorService.recommendSafestRoute(request);
        return ResponseEntity.ok(response);
    }
}
