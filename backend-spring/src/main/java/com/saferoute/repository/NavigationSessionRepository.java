package com.saferoute.repository;

import com.saferoute.model.NavigationSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NavigationSessionRepository extends JpaRepository<NavigationSession, UUID> {
    List<NavigationSession> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
