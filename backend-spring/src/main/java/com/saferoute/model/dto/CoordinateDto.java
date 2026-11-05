package com.saferoute.model.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CoordinateDto {
    private Double latitude;
    private Double longitude;

    public CoordinateDto() {
    }

    public CoordinateDto(Double latitude, Double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public static CoordinateDtoBuilder builder() {
        return new CoordinateDtoBuilder();
    }

    public static class CoordinateDtoBuilder {
        private Double latitude;
        private Double longitude;

        CoordinateDtoBuilder() {
        }

        public CoordinateDtoBuilder latitude(Double latitude) {
            this.latitude = latitude;
            return this;
        }

        public CoordinateDtoBuilder longitude(Double longitude) {
            this.longitude = longitude;
            return this;
        }

        public CoordinateDto build() {
            return new CoordinateDto(this.latitude, this.longitude);
        }
    }
}
