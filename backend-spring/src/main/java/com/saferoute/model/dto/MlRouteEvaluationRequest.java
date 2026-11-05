package com.saferoute.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class MlRouteEvaluationRequest {

    private CoordinateDto destination;
    private CoordinateDto origin;

    @JsonProperty("departure_time")
    private String departureTime;

    private List<RouteCandidateDto> routes;

    @JsonProperty("w1_crime")
    @Builder.Default
    private Double w1Crime = 0.40;

    @JsonProperty("w2_crowd")
    @Builder.Default
    private Double w2Crowd = 0.25;

    @JsonProperty("w3_lighting")
    @Builder.Default
    private Double w3Lighting = 0.25;

    @JsonProperty("w4_time")
    @Builder.Default
    private Double w4Time = 0.10;

    @JsonProperty("alpha_distance")
    @Builder.Default
    private Double alphaDistance = 0.001;

    public MlRouteEvaluationRequest() {
    }

    public MlRouteEvaluationRequest(CoordinateDto destination, CoordinateDto origin, String departureTime,
                                   List<RouteCandidateDto> routes, Double w1Crime, Double w2Crowd,
                                   Double w3Lighting, Double w4Time, Double alphaDistance) {
        this.destination = destination;
        this.origin = origin;
        this.departureTime = departureTime;
        this.routes = routes;
        this.w1Crime = w1Crime != null ? w1Crime : 0.40;
        this.w2Crowd = w2Crowd != null ? w2Crowd : 0.25;
        this.w3Lighting = w3Lighting != null ? w3Lighting : 0.25;
        this.w4Time = w4Time != null ? w4Time : 0.10;
        this.alphaDistance = alphaDistance != null ? alphaDistance : 0.001;
    }

    public CoordinateDto getDestination() {
        return destination;
    }

    public void setDestination(CoordinateDto destination) {
        this.destination = destination;
    }

    public CoordinateDto getOrigin() {
        return origin;
    }

    public void setOrigin(CoordinateDto origin) {
        this.origin = origin;
    }

    public String getDepartureTime() {
        return departureTime;
    }

    public void setDepartureTime(String departureTime) {
        this.departureTime = departureTime;
    }

    public List<RouteCandidateDto> getRoutes() {
        return routes;
    }

    public void setRoutes(List<RouteCandidateDto> routes) {
        this.routes = routes;
    }

    public Double getW1Crime() {
        return w1Crime;
    }

    public void setW1Crime(Double w1Crime) {
        this.w1Crime = w1Crime;
    }

    public Double getW2Crowd() {
        return w2Crowd;
    }

    public void setW2Crowd(Double w2Crowd) {
        this.w2Crowd = w2Crowd;
    }

    public Double getW3Lighting() {
        return w3Lighting;
    }

    public void setW3Lighting(Double w3Lighting) {
        this.w3Lighting = w3Lighting;
    }

    public Double getW4Time() {
        return w4Time;
    }

    public void setW4Time(Double w4Time) {
        this.w4Time = w4Time;
    }

    public Double getAlphaDistance() {
        return alphaDistance;
    }

    public void setAlphaDistance(Double alphaDistance) {
        this.alphaDistance = alphaDistance;
    }

    public static MlRouteEvaluationRequestBuilder builder() {
        return new MlRouteEvaluationRequestBuilder();
    }

    public static class MlRouteEvaluationRequestBuilder {
        private CoordinateDto destination;
        private CoordinateDto origin;
        private String departureTime;
        private List<RouteCandidateDto> routes;
        private Double w1Crime = 0.40;
        private Double w2Crowd = 0.25;
        private Double w3Lighting = 0.25;
        private Double w4Time = 0.10;
        private Double alphaDistance = 0.001;

        MlRouteEvaluationRequestBuilder() {
        }

        public MlRouteEvaluationRequestBuilder destination(CoordinateDto destination) {
            this.destination = destination;
            return this;
        }

        public MlRouteEvaluationRequestBuilder origin(CoordinateDto origin) {
            this.origin = origin;
            return this;
        }

        public MlRouteEvaluationRequestBuilder departureTime(String departureTime) {
            this.departureTime = departureTime;
            return this;
        }

        public MlRouteEvaluationRequestBuilder routes(List<RouteCandidateDto> routes) {
            this.routes = routes;
            return this;
        }

        public MlRouteEvaluationRequestBuilder w1Crime(Double w1Crime) {
            this.w1Crime = w1Crime;
            return this;
        }

        public MlRouteEvaluationRequestBuilder w2Crowd(Double w2Crowd) {
            this.w2Crowd = w2Crowd;
            return this;
        }

        public MlRouteEvaluationRequestBuilder w3Lighting(Double w3Lighting) {
            this.w3Lighting = w3Lighting;
            return this;
        }

        public MlRouteEvaluationRequestBuilder w4Time(Double w4Time) {
            this.w4Time = w4Time;
            return this;
        }

        public MlRouteEvaluationRequestBuilder alphaDistance(Double alphaDistance) {
            this.alphaDistance = alphaDistance;
            return this;
        }

        public MlRouteEvaluationRequest build() {
            return new MlRouteEvaluationRequest(destination, origin, departureTime, routes, w1Crime, w2Crowd, w3Lighting, w4Time, alphaDistance);
        }
    }
}
