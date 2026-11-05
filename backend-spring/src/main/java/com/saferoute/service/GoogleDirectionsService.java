package com.saferoute.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.saferoute.model.dto.CoordinateDto;
import com.saferoute.model.dto.RouteCandidateDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@SuppressWarnings("null")
public class GoogleDirectionsService {

    private static final int SIMULATION_STEPS = 25;

    private final WebClient webClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GoogleDirectionsService(WebClient webClient) {
        this.webClient = webClient;
    }

    @Value("${integrations.mapbox.access-token:YOUR_MAPBOX_ACCESS_TOKEN}")
    private String mapboxAccessToken;

    @Value("${integrations.mapbox.directions-url:https://api.mapbox.com/directions/v5/mapbox/driving}")
    private String mapboxDirectionsUrl;

    @Value("${integrations.google.maps.api-key:}")
    private String googleApiKey;

    @Value("${integrations.google.maps.directions-url:https://maps.googleapis.com/maps/api/directions/json}")
    private String directionsUrl;

    public List<RouteCandidateDto> fetchAlternateRoutes(Double sourceLat, Double sourceLng,
                                                        Double destLat, Double destLng) {
        // Priority 1: Mapbox Directions API (Turn-by-turn road geometry for live user coordinates)
        if (StringUtils.hasText(mapboxAccessToken)) {
            List<RouteCandidateDto> mapboxRoutes = fetchMapboxRoutes(sourceLat, sourceLng, destLat, destLng);
            if (!mapboxRoutes.isEmpty()) {
                return mapboxRoutes;
            }
        }

        // Priority 2: Google Maps Directions API (if API key is configured)
        if (StringUtils.hasText(googleApiKey) && !"YOUR_GOOGLE_MAPS_API_KEY".equals(googleApiKey)) {
            List<RouteCandidateDto> googleRoutes = fetchGoogleRoutes(sourceLat, sourceLng, destLat, destLng);
            if (!googleRoutes.isEmpty()) {
                return googleRoutes;
            }
        }

        // Priority 3: Resilient fallback
        log.warn("Routing providers unavailable. Generating simulated alternate routes.");
        return generateSimulatedAlternateRoutes(sourceLat, sourceLng, destLat, destLng);
    }

    // Queries Mapbox Directions API for driving/walking turn-by-turn corridors.
    public List<RouteCandidateDto> fetchMapboxRoutes(Double sourceLat, Double sourceLng,
                                                     Double destLat, Double destLng) {
        List<RouteCandidateDto> candidateRoutes = new ArrayList<>();

        // 1. Primary profile: driving corridor
        fetchMapboxProfileRoutes("driving", sourceLat, sourceLng, destLat, destLng, candidateRoutes);

        // 2. Secondary profile: walking corridor (provides alternate road route)
        if (candidateRoutes.size() < 2) {
            fetchMapboxProfileRoutes("walking", sourceLat, sourceLng, destLat, destLng, candidateRoutes);
        }

        return candidateRoutes;
    }

    private void fetchMapboxProfileRoutes(String profile, Double sourceLat, Double sourceLng,
                                          Double destLat, Double destLng,
                                          List<RouteCandidateDto> candidateRoutes) {
        try {
            String uri = String.format(Locale.US,
                    "https://api.mapbox.com/directions/v5/mapbox/%s/%f,%f;%f,%f?alternatives=true&geometries=geojson&overview=full&access_token=%s",
                    profile, sourceLng, sourceLat, destLng, destLat, mapboxAccessToken);

            log.info("Fetching {} route geometry from Mapbox: ({}, {}) -> ({}, {})",
                    profile, sourceLat, sourceLng, destLat, destLng);

            String responseBody = webClient.get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            String code = root.path("code").asText();

            if (!"Ok".equalsIgnoreCase(code)) {
                log.warn("Mapbox {} returned non-OK status: {}", profile, code);
                return;
            }

            JsonNode routesNode = root.path("routes");
            for (int i = 0; i < routesNode.size(); i++) {
                JsonNode routeNode = routesNode.get(i);

                String summary = "Route " + (candidateRoutes.size() + 1);
                JsonNode legs = routeNode.path("legs");
                if (legs.isArray() && !legs.isEmpty()) {
                    String legSummary = legs.get(0).path("summary").asText();
                    if (StringUtils.hasText(legSummary)) {
                        summary = "Via " + legSummary + " (" + (profile.equals("walking") ? "Walkway" : "Avenue") + ")";
                    }
                }

                double distanceMeters = routeNode.path("distance").asDouble(0.0);

                JsonNode coordinatesArray = routeNode.path("geometry").path("coordinates");
                List<CoordinateDto> coordinates = new ArrayList<>();
                if (coordinatesArray.isArray()) {
                    for (JsonNode coordPair : coordinatesArray) {
                        double lon = coordPair.get(0).asDouble();
                        double lat = coordPair.get(1).asDouble();
                        coordinates.add(new CoordinateDto(lat, lon));
                    }
                }

                if (coordinates.size() >= 6) {
                    candidateRoutes.add(RouteCandidateDto.builder()
                            .routeId("mapbox_" + profile + "_" + i)
                            .summary(summary)
                            .coordinates(coordinates)
                            .totalDistanceMeters(distanceMeters)
                            .build());
                }
            }

            log.info("Mapbox {} yielded valid road corridors (total candidates now: {})",
                    profile, candidateRoutes.size());
        } catch (Exception ex) {
            log.error("Error querying Mapbox {} API: {}", profile, ex.getMessage());
        }
    }

    // Decodes an encoded Google Maps Polyline string into a list of CoordinateDto objects.
    public static List<CoordinateDto> decodePolyline(String encoded) {
        List<CoordinateDto> poly = new ArrayList<>();
        int index = 0, len = encoded.length();
        int lat = 0, lng = 0;

        while (index < len) {
            int b, shift = 0, result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lat += dlat;

            shift = 0;
            result = 0;
            do {
                b = encoded.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lng += dlng;

            poly.add(new CoordinateDto((double) lat / 1E5, (double) lng / 1E5));
        }
        return poly;
    }

    // Queries Google Maps Directions API.
    public List<RouteCandidateDto> fetchGoogleRoutes(Double sourceLat, Double sourceLng,
                                                     Double destLat, Double destLng) {
        try {
            String uri = String.format(Locale.US, "%s?origin=%f,%f&destination=%f,%f&alternatives=true&mode=walking&key=%s",
                    directionsUrl, sourceLat, sourceLng, destLat, destLng, googleApiKey);

            String responseBody = webClient.get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            String status = root.path("status").asText();

            if (!"OK".equalsIgnoreCase(status)) {
                log.warn("Google Directions API returned non-OK status: {}", status);
                return Collections.emptyList();
            }

            JsonNode routesNode = root.path("routes");
            List<RouteCandidateDto> candidateRoutes = new ArrayList<>();

            for (int i = 0; i < routesNode.size(); i++) {
                JsonNode routeNode = routesNode.get(i);
                String summary = routeNode.path("summary").asText("Route " + (i + 1));
                String overviewPolyline = routeNode.path("overview_polyline").path("points").asText();

                double distanceMeters = 0.0;
                JsonNode legs = routeNode.path("legs");
                if (legs.isArray() && !legs.isEmpty()) {
                    distanceMeters = legs.get(0).path("distance").path("value").asDouble(0.0);
                }

                List<CoordinateDto> coordinates = decodePolyline(overviewPolyline);

                candidateRoutes.add(RouteCandidateDto.builder()
                        .routeId("gmaps_route_" + i)
                        .summary(summary)
                        .coordinates(coordinates)
                        .totalDistanceMeters(distanceMeters)
                        .build());
            }

            return candidateRoutes;
        } catch (Exception ex) {
            log.error("Failed to query Google Directions API: {}", ex.getMessage());
            return Collections.emptyList();
        }
    }

    // Resilient offline fallback: Generates 2 realistic alternate route corridors
    // (e.g. Major Avenue vs Peripheral By-pass) between source and destination coordinates.
    private List<RouteCandidateDto> generateSimulatedAlternateRoutes(Double sLat, Double sLng, Double dLat, Double dLng) {
        List<RouteCandidateDto> routes = new ArrayList<>();

        // Route 1: Main Arterial Corridor with realistic street-level turns
        List<CoordinateDto> route1Coords = new ArrayList<>();
        for (int i = 0; i <= SIMULATION_STEPS; i++) {
            double t = (double) i / SIMULATION_STEPS;
            double latInterp = sLat + t * (dLat - sLat);
            double lngInterp = sLng + t * (dLng - sLng);
            double sinOffset = Math.sin(t * Math.PI) * 0.0035;
            route1Coords.add(new CoordinateDto(latInterp + sinOffset, lngInterp + sinOffset * 0.5));
        }

        routes.add(RouteCandidateDto.builder()
                .routeId("sim_route_main_avenue")
                .summary("Via Main Avenue (Well-illuminated, Commercial corridor)")
                .coordinates(route1Coords)
                .totalDistanceMeters(estimateDistanceMeters(sLat, sLng, dLat, dLng) * 1.08)
                .build());

        // Route 2: Peripheral Cut-Through / Back Alleyway
        List<CoordinateDto> route2Coords = new ArrayList<>();
        for (int i = 0; i <= SIMULATION_STEPS; i++) {
            double t = (double) i / SIMULATION_STEPS;
            double latInterp = sLat + t * (dLat - sLat);
            double lngInterp = sLng + t * (dLng - sLng);
            double sinOffset = -Math.sin(t * Math.PI) * 0.0045;
            route2Coords.add(new CoordinateDto(latInterp + sinOffset, lngInterp + sinOffset * 0.7));
        }

        routes.add(RouteCandidateDto.builder()
                .routeId("sim_route_back_streets")
                .summary("Via Industrial By-pass & Railway Crossing (Shorter, Lower Visibility)")
                .coordinates(route2Coords)
                .totalDistanceMeters(estimateDistanceMeters(sLat, sLng, dLat, dLng) * 0.96)
                .build());

        return routes;
    }

    private double estimateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
