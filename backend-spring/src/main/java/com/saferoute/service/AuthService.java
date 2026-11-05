package com.saferoute.service;

import com.saferoute.config.JwtTokenProvider;
import com.saferoute.model.User;
import com.saferoute.model.dto.AuthRequest;
import com.saferoute.model.dto.AuthResponse;
import com.saferoute.model.dto.RegisterRequest;
import com.saferoute.repository.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@SuppressWarnings("null")
public class AuthService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuthenticationManager authenticationManager;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider,
                       AuthenticationManager authenticationManager) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.authenticationManager = authenticationManager;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email is already registered: " + request.getEmail());
        }

        User user = User.builder()
                .name(request.getName().trim())
                .email(request.getEmail().trim().toLowerCase())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .emergencyContact(request.getEmergencyContact().trim())
                .build();

        User savedUser = userRepository.save(user);
        log.info("Registered new user with ID: {}", savedUser.getId());

        String jwt = tokenProvider.generateToken(savedUser);

        return AuthResponse.builder()
                .token(jwt)
                .type("Bearer")
                .userId(savedUser.getId())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .emergencyContact(savedUser.getEmergencyContact())
                .build();
    }

    public AuthResponse login(AuthRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail().trim().toLowerCase(),
                        request.getPassword()
                )
        );

        User user = userRepository.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + request.getEmail()));

        String jwt = tokenProvider.generateToken(user);
        log.info("User logged in successfully: {}", user.getEmail());

        return AuthResponse.builder()
                .token(jwt)
                .type("Bearer")
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .emergencyContact(user.getEmergencyContact())
                .build();
    }
}
