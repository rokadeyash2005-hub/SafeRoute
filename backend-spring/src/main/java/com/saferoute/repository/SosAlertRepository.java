package com.saferoute.repository;

import com.saferoute.model.SosAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SosAlertRepository extends JpaRepository<SosAlert, UUID> {
    List<SosAlert> findByUserIdOrderByDispatchedAtDesc(UUID userId);
}
