package com.saferoute.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
@Builder
public class MlRouteEvaluationResponse {

    private String status;

    @JsonProperty("safest_route_index")
    private Integer safestRouteIndex;

    @JsonProperty("recommended_polyline")
    private List<CoordinateDto> recommendedPolyline;

    @JsonProperty("composite_risk_score")
    private Double compositeRiskScore;

    @JsonProperty("safety_rating")
    private Double safetyRating;

    @JsonProperty("total_evaluated_routes")
    private Integer totalEvaluatedRoutes;

    @JsonProperty("detailed_segment_analysis")
    private List<Map<String, Object>> detailedSegmentAnalysis;

    @JsonProperty("all_evaluated_routes")
    private List<Map<String, Object>> allEvaluatedRoutes;

    public MlRouteEvaluationResponse() {
    }

    public MlRouteEvaluationResponse(String status, Integer safestRouteIndex, List<CoordinateDto> recommendedPolyline,
                                     Double compositeRiskScore, Double safetyRating, Integer totalEvaluatedRoutes,
                                     List<Map<String, Object>> detailedSegmentAnalysis,
                                     List<Map<String, Object>> allEvaluatedRoutes) {
        this.status = status;
        this.safestRouteIndex = safestRouteIndex;
        this.recommendedPolyline = recommendedPolyline;
        this.compositeRiskScore = compositeRiskScore;
        this.safetyRating = safetyRating;
        this.totalEvaluatedRoutes = totalEvaluatedRoutes;
        this.detailedSegmentAnalysis = detailedSegmentAnalysis;
        this.allEvaluatedRoutes = allEvaluatedRoutes;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getSafestRouteIndex() {
        return safestRouteIndex;
    }

    public void setSafestRouteIndex(Integer safestRouteIndex) {
        this.safestRouteIndex = safestRouteIndex;
    }

    public List<CoordinateDto> getRecommendedPolyline() {
        return recommendedPolyline;
    }

    public void setRecommendedPolyline(List<CoordinateDto> recommendedPolyline) {
        this.recommendedPolyline = recommendedPolyline;
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

    public static MlRouteEvaluationResponseBuilder builder() {
        return new MlRouteEvaluationResponseBuilder();
    }

    public static class MlRouteEvaluationResponseBuilder {
        private String status;
        private Integer safestRouteIndex;
        private List<CoordinateDto> recommendedPolyline;
        private Double compositeRiskScore;
        private Double safetyRating;
        private Integer totalEvaluatedRoutes;
        private List<Map<String, Object>> detailedSegmentAnalysis;
        private List<Map<String, Object>> allEvaluatedRoutes;

        MlRouteEvaluationResponseBuilder() {
        }

        public MlRouteEvaluationResponseBuilder status(String status) {
            this.status = status;
            return this;
        }

        public MlRouteEvaluationResponseBuilder safestRouteIndex(Integer safestRouteIndex) {
            this.safestRouteIndex = safestRouteIndex;
            return this;
        }

        public MlRouteEvaluationResponseBuilder recommendedPolyline(List<CoordinateDto> recommendedPolyline) {
            this.recommendedPolyline = recommendedPolyline;
            return this;
        }

        public MlRouteEvaluationResponseBuilder compositeRiskScore(Double compositeRiskScore) {
            this.compositeRiskScore = compositeRiskScore;
            return this;
        }

        public MlRouteEvaluationResponseBuilder safetyRating(Double safetyRating) {
            this.safetyRating = safetyRating;
            return this;
        }

        public MlRouteEvaluationResponseBuilder totalEvaluatedRoutes(Integer totalEvaluatedRoutes) {
            this.totalEvaluatedRoutes = totalEvaluatedRoutes;
            return this;
        }

        public MlRouteEvaluationResponseBuilder detailedSegmentAnalysis(List<Map<String, Object>> detailedSegmentAnalysis) {
            this.detailedSegmentAnalysis = detailedSegmentAnalysis;
            return this;
        }

        public MlRouteEvaluationResponseBuilder allEvaluatedRoutes(List<Map<String, Object>> allEvaluatedRoutes) {
            this.allEvaluatedRoutes = allEvaluatedRoutes;
            return this;
        }

        public MlRouteEvaluationResponse build() {
            return new MlRouteEvaluationResponse(status, safestRouteIndex, recommendedPolyline,
                    compositeRiskScore, safetyRating, totalEvaluatedRoutes, detailedSegmentAnalysis, allEvaluatedRoutes);
        }
    }
}
