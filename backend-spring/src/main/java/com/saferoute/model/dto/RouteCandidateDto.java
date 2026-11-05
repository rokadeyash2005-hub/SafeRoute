package com.saferoute.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class RouteCandidateDto {

    @JsonProperty("route_id")
    private String routeId;

    private String summary;

    private List<CoordinateDto> coordinates;

    @JsonProperty("total_distance_meters")
    private Double totalDistanceMeters;

    public RouteCandidateDto() {
    }

    public RouteCandidateDto(String routeId, String summary, List<CoordinateDto> coordinates, Double totalDistanceMeters) {
        this.routeId = routeId;
        this.summary = summary;
        this.coordinates = coordinates;
        this.totalDistanceMeters = totalDistanceMeters;
    }

    public String getRouteId() {
        return routeId;
    }

    public void setRouteId(String routeId) {
        this.routeId = routeId;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public List<CoordinateDto> getCoordinates() {
        return coordinates;
    }

    public void setCoordinates(List<CoordinateDto> coordinates) {
        this.coordinates = coordinates;
    }

    public Double getTotalDistanceMeters() {
        return totalDistanceMeters;
    }

    public void setTotalDistanceMeters(Double totalDistanceMeters) {
        this.totalDistanceMeters = totalDistanceMeters;
    }

    public static RouteCandidateDtoBuilder builder() {
        return new RouteCandidateDtoBuilder();
    }

    public static class RouteCandidateDtoBuilder {
        private String routeId;
        private String summary;
        private List<CoordinateDto> coordinates;
        private Double totalDistanceMeters;

        RouteCandidateDtoBuilder() {
        }

        public RouteCandidateDtoBuilder routeId(String routeId) {
            this.routeId = routeId;
            return this;
        }

        public RouteCandidateDtoBuilder summary(String summary) {
            this.summary = summary;
            return this;
        }

        public RouteCandidateDtoBuilder coordinates(List<CoordinateDto> coordinates) {
            this.coordinates = coordinates;
            return this;
        }

        public RouteCandidateDtoBuilder totalDistanceMeters(Double totalDistanceMeters) {
            this.totalDistanceMeters = totalDistanceMeters;
            return this;
        }

        public RouteCandidateDto build() {
            return new RouteCandidateDto(this.routeId, this.summary, this.coordinates, this.totalDistanceMeters);
        }
    }
}
