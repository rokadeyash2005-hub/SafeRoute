package com.saferoute.model.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class RouteRecommendRequest {

    @NotNull(message = "sourceLat is required")
    private Double sourceLat;

    @NotNull(message = "sourceLng is required")
    private Double sourceLng;

    @NotNull(message = "destLat is required")
    private Double destLat;

    @NotNull(message = "destLng is required")
    private Double destLng;

    private LocalDateTime departureTime;

    public RouteRecommendRequest() {
    }

    public RouteRecommendRequest(Double sourceLat, Double sourceLng, Double destLat, Double destLng, LocalDateTime departureTime) {
        this.sourceLat = sourceLat;
        this.sourceLng = sourceLng;
        this.destLat = destLat;
        this.destLng = destLng;
        this.departureTime = departureTime;
    }

    public Double getSourceLat() {
        return sourceLat;
    }

    public void setSourceLat(Double sourceLat) {
        this.sourceLat = sourceLat;
    }

    public Double getSourceLng() {
        return sourceLng;
    }

    public void setSourceLng(Double sourceLng) {
        this.sourceLng = sourceLng;
    }

    public Double getDestLat() {
        return destLat;
    }

    public void setDestLat(Double destLat) {
        this.destLat = destLat;
    }

    public Double getDestLng() {
        return destLng;
    }

    public void setDestLng(Double destLng) {
        this.destLng = destLng;
    }

    public LocalDateTime getDepartureTime() {
        return departureTime;
    }

    public void setDepartureTime(LocalDateTime departureTime) {
        this.departureTime = departureTime;
    }

    public static RouteRecommendRequestBuilder builder() {
        return new RouteRecommendRequestBuilder();
    }

    public static class RouteRecommendRequestBuilder {
        private Double sourceLat;
        private Double sourceLng;
        private Double destLat;
        private Double destLng;
        private LocalDateTime departureTime;

        RouteRecommendRequestBuilder() {
        }

        public RouteRecommendRequestBuilder sourceLat(Double sourceLat) {
            this.sourceLat = sourceLat;
            return this;
        }

        public RouteRecommendRequestBuilder sourceLng(Double sourceLng) {
            this.sourceLng = sourceLng;
            return this;
        }

        public RouteRecommendRequestBuilder destLat(Double destLat) {
            this.destLat = destLat;
            return this;
        }

        public RouteRecommendRequestBuilder destLng(Double destLng) {
            this.destLng = destLng;
            return this;
        }

        public RouteRecommendRequestBuilder departureTime(LocalDateTime departureTime) {
            this.departureTime = departureTime;
            return this;
        }

        public RouteRecommendRequest build() {
            return new RouteRecommendRequest(this.sourceLat, this.sourceLng, this.destLat, this.destLng, this.departureTime);
        }
    }
}
