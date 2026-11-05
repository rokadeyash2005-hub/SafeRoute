package com.saferoute.model.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
public class RouteRecommendationResponse {

    private UUID sessionId;
    private Integer safestRouteIndex;
    private String routeSummary;
    private Double compositeRiskScore;
    private Double safetyRating;
    private Double totalDistanceMeters;
    private List<CoordinateDto> recommendedPolyline;
    private List<CoordinateDto> alternatePolyline;
    private Integer totalEvaluatedRoutes;
    private List<Map<String, Object>> detailedSegmentAnalysis;
    private List<Map<String, Object>> allEvaluatedRoutes;
    private LocalDateTime evaluatedAt;

    public RouteRecommendationResponse() {
    }

    public RouteRecommendationResponse(UUID sessionId, Integer safestRouteIndex, String routeSummary,
                                       Double compositeRiskScore, Double safetyRating, Double totalDistanceMeters,
                                       List<CoordinateDto> recommendedPolyline, List<CoordinateDto> alternatePolyline,
                                       Integer totalEvaluatedRoutes,
                                       List<Map<String, Object>> detailedSegmentAnalysis,
                                       List<Map<String, Object>> allEvaluatedRoutes, LocalDateTime evaluatedAt) {
        this.sessionId = sessionId;
        this.safestRouteIndex = safestRouteIndex;
        this.routeSummary = routeSummary;
        this.compositeRiskScore = compositeRiskScore;
        this.safetyRating = safetyRating;
        this.totalDistanceMeters = totalDistanceMeters;
        this.recommendedPolyline = recommendedPolyline;
        this.alternatePolyline = alternatePolyline;
        this.totalEvaluatedRoutes = totalEvaluatedRoutes;
        this.detailedSegmentAnalysis = detailedSegmentAnalysis;
        this.allEvaluatedRoutes = allEvaluatedRoutes;
        this.evaluatedAt = evaluatedAt;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public void setSessionId(UUID sessionId) {
        this.sessionId = sessionId;
    }

    public Integer getSafestRouteIndex() {
        return safestRouteIndex;
    }

    public void setSafestRouteIndex(Integer safestRouteIndex) {
        this.safestRouteIndex = safestRouteIndex;
    }

    public String getRouteSummary() {
        return routeSummary;
    }

    public void setRouteSummary(String routeSummary) {
        this.routeSummary = routeSummary;
    }

    public Double getCompositeRiskScore() {
        return compositeRiskScore;
    }

    public void setCompositeRiskScore(Double compositeRiskScore) {
        this.compositeRiskScore = compositeRiskScore;
    }

    public Double getSafetyRating() {
        return safetyRating;
    }

    public void setSafetyRating(Double safetyRating) {
        this.safetyRating = safetyRating;
    }

    public Double getTotalDistanceMeters() {
        return totalDistanceMeters;
    }

    public void setTotalDistanceMeters(Double totalDistanceMeters) {
        this.totalDistanceMeters = totalDistanceMeters;
    }

    public List<CoordinateDto> getRecommendedPolyline() {
        return recommendedPolyline;
    }

    public void setRecommendedPolyline(List<CoordinateDto> recommendedPolyline) {
        this.recommendedPolyline = recommendedPolyline;
    }

    public List<CoordinateDto> getAlternatePolyline() {
        return alternatePolyline;
    }

    public void setAlternatePolyline(List<CoordinateDto> alternatePolyline) {
        this.alternatePolyline = alternatePolyline;
    }

    public Integer getTotalEvaluatedRoutes() {
        return totalEvaluatedRoutes;
    }

    public void setTotalEvaluatedRoutes(Integer totalEvaluatedRoutes) {
        this.totalEvaluatedRoutes = totalEvaluatedRoutes;
    }

    public List<Map<String, Object>> getDetailedSegmentAnalysis() {
        return detailedSegmentAnalysis;
    }

    public void setDetailedSegmentAnalysis(List<Map<String, Object>> detailedSegmentAnalysis) {
        this.detailedSegmentAnalysis = detailedSegmentAnalysis;
    }

    public List<Map<String, Object>> getAllEvaluatedRoutes() {
        return allEvaluatedRoutes;
    }

    public void setAllEvaluatedRoutes(List<Map<String, Object>> allEvaluatedRoutes) {
        this.allEvaluatedRoutes = allEvaluatedRoutes;
    }

    public LocalDateTime getEvaluatedAt() {
        return evaluatedAt;
    }

    public void setEvaluatedAt(LocalDateTime evaluatedAt) {
        this.evaluatedAt = evaluatedAt;
    }

    public static RouteRecommendationResponseBuilder builder() {
        return new RouteRecommendationResponseBuilder();
    }

    public static class RouteRecommendationResponseBuilder {
        private UUID sessionId;
        private Integer safestRouteIndex;
        private String routeSummary;
        private Double compositeRiskScore;
        private Double safetyRating;
        private Double totalDistanceMeters;
        private List<CoordinateDto> recommendedPolyline;
        private List<CoordinateDto> alternatePolyline;
        private Integer totalEvaluatedRoutes;
        private List<Map<String, Object>> detailedSegmentAnalysis;
        private List<Map<String, Object>> allEvaluatedRoutes;
        private LocalDateTime evaluatedAt;

        RouteRecommendationResponseBuilder() {
        }

        public RouteRecommendationResponseBuilder sessionId(UUID sessionId) {
            this.sessionId = sessionId;
            return this;
        }

        public RouteRecommendationResponseBuilder safestRouteIndex(Integer safestRouteIndex) {
            this.safestRouteIndex = safestRouteIndex;
            return this;
        }

        public RouteRecommendationResponseBuilder routeSummary(String routeSummary) {
            this.routeSummary = routeSummary;
            return this;
        }

        public RouteRecommendationResponseBuilder compositeRiskScore(Double compositeRiskScore) {
            this.compositeRiskScore = compositeRiskScore;
            return this;
        }

        public RouteRecommendationResponseBuilder safetyRating(Double safetyRating) {
            this.safetyRating = safetyRating;
            return this;
        }

        public RouteRecommendationResponseBuilder totalDistanceMeters(Double totalDistanceMeters) {
            this.totalDistanceMeters = totalDistanceMeters;
            return this;
        }

        public RouteRecommendationResponseBuilder recommendedPolyline(List<CoordinateDto> recommendedPolyline) {
            this.recommendedPolyline = recommendedPolyline;
            return this;
        }

        public RouteRecommendationResponseBuilder alternatePolyline(List<CoordinateDto> alternatePolyline) {
            this.alternatePolyline = alternatePolyline;
            return this;
        }

        public RouteRecommendationResponseBuilder totalEvaluatedRoutes(Integer totalEvaluatedRoutes) {
            this.totalEvaluatedRoutes = totalEvaluatedRoutes;
            return this;
        }

        public RouteRecommendationResponseBuilder detailedSegmentAnalysis(List<Map<String, Object>> detailedSegmentAnalysis) {
            this.detailedSegmentAnalysis = detailedSegmentAnalysis;
            return this;
        }

        public RouteRecommendationResponseBuilder allEvaluatedRoutes(List<Map<String, Object>> allEvaluatedRoutes) {
            this.allEvaluatedRoutes = allEvaluatedRoutes;
            return this;
        }

        public RouteRecommendationResponseBuilder evaluatedAt(LocalDateTime evaluatedAt) {
            this.evaluatedAt = evaluatedAt;
            return this;
        }

        public RouteRecommendationResponse build() {
            return new RouteRecommendationResponse(sessionId, safestRouteIndex, routeSummary,
                    compositeRiskScore, safetyRating, totalDistanceMeters, recommendedPolyline,
                    alternatePolyline, totalEvaluatedRoutes, detailedSegmentAnalysis, allEvaluatedRoutes, evaluatedAt);
        }
    }
}
