package com.saferoute.controller;

import com.saferoute.model.dto.SosRequest;
import com.saferoute.model.dto.SosResponse;
import com.saferoute.service.SafetyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/safety")
@RequiredArgsConstructor
public class SafetyController {

    private final SafetyService safetyService;

    @PostMapping("/sos")
    public ResponseEntity<SosResponse> triggerEmergencySos(@Valid @RequestBody SosRequest request) {
        SosResponse response = safetyService.triggerEmergencySos(request);
        return ResponseEntity.ok(response);
    }
}
