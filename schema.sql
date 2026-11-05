-- ============================================================================
-- Project: Crowdsourced Real-Time Women Safety and Safe-Route Recommendation
-- Project Code: MCA-P17
-- Module: Database Tier - PostGIS Spatial Schema & Seed Migration
-- Database: PostgreSQL 14+ with PostGIS 3+
-- Author: Principal Geospatial AI Architect
-- Note: In PostGIS ST_MakePoint(X, Y), X is LONGITUDE and Y is LATITUDE (SRID: 4326 - WGS 84).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXTENSIONS SETUP
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For gen_random_uuid()

-- ----------------------------------------------------------------------------
-- 2. SCHEMA DEFINITIONS (TABLES & CONSTRAINTS)
-- ----------------------------------------------------------------------------

-- Table: users
-- Stores registered mobile users and emergency contact payloads
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    emergency_contact VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table: crime_hotspots
-- Stores historical and reported crime occurrences with spatial coordinates
CREATE TABLE IF NOT EXISTS crime_hotspots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    crime_type VARCHAR(80) NOT NULL,
    severity_score INT NOT NULL CHECK (severity_score BETWEEN 1 AND 10),
    incident_time TIMESTAMPTZ NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table: safety_ratings
-- Real-time crowdsourced telemetry on infrastructure, lighting, and perceived safety
CREATE TABLE IF NOT EXISTS safety_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    street_name VARCHAR(180) NOT NULL,
    lighting_score INT NOT NULL CHECK (lighting_score BETWEEN 1 AND 5),
    crowd_density INT NOT NULL CHECK (crowd_density BETWEEN 1 AND 5),
    safety_score INT NOT NULL CHECK (safety_score BETWEEN 1 AND 5),
    location GEOMETRY(Point, 4326) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 3. SPATIAL & PERFORMANCE INDEXING
-- ----------------------------------------------------------------------------

-- GiST (Generalized Search Tree) Indexes for sub-second spatial bounding-box & distance operations
CREATE INDEX IF NOT EXISTS idx_crime_hotspots_location_gist 
    ON crime_hotspots USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_safety_ratings_location_gist 
    ON safety_ratings USING GIST (location);

-- Auxiliary B-Tree indexes for relational joins and temporal filtering
CREATE INDEX IF NOT EXISTS idx_safety_ratings_user_id 
    ON safety_ratings(user_id);

CREATE INDEX IF NOT EXISTS idx_crime_hotspots_incident_time 
    ON crime_hotspots(incident_time);

CREATE INDEX IF NOT EXISTS idx_safety_ratings_recorded_at 
    ON safety_ratings(recorded_at);

-- ----------------------------------------------------------------------------
-- 4. SEED DATA - MOCK USERS
-- ----------------------------------------------------------------------------
INSERT INTO users (id, name, email, password_hash, emergency_contact, created_at)
VALUES
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Aarohi Sharma', 'aarohi.sharma@example.com', '$2a$12$e80yV9u5eM7Hh1q1VqT3qOPkIqX3aKqL6d1fQoZ3n9.2KzC5aM4q.', '+919876543210', '2026-01-10 09:30:00+05:30'),
    ('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Priya Verma', 'priya.verma@example.com', '$2a$12$j45yX1u2eM9Hh2w8VqT3qOPkIqX3aKqL6d1fQoZ3n9.2KzC5aM4q.', '+919812345678', '2026-01-12 11:15:00+05:30'),
    ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Sneha Kulkarni', 'sneha.k@example.com', '$2a$12$l78yY3u4eM1Hh3y9VqT3qOPkIqX3aKqL6d1fQoZ3n9.2KzC5aM4q.', '+919765432109', '2026-01-15 14:45:00+05:30'),
    ('d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Ananya Patel', 'ananya.p@example.com', '$2a$12$m90yZ5u6eM3Hh4z1VqT3qOPkIqX3aKqL6d1fQoZ3n9.2KzC5aM4q.', '+919923456781', '2026-01-18 16:20:00+05:30')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. SEED DATA - 10 REALISTIC CRIME HOTSPOTS (SRID 4326: Lon, Lat)
-- Urban Corridor: Central/South Delhi & NCR Region
-- ----------------------------------------------------------------------------
INSERT INTO crime_hotspots (id, crime_type, severity_score, incident_time, location, created_at)
VALUES
    -- 1. Dark pedestrian underpass near railway crossing
    ('e1000001-0000-0000-0000-000000000001', 'Physical Assault & Mugging', 9, '2026-01-05 23:45:00+05:30', ST_SetSRID(ST_MakePoint(77.2185, 28.6432), 4326), '2026-01-06 08:00:00+05:30'),
    
    -- 2. Poorly illuminated alley adjacent to transit hub
    ('e1000002-0000-0000-0000-000000000002', 'Verbal Harassment & Stalking', 7, '2026-01-08 21:15:00+05:30', ST_SetSRID(ST_MakePoint(77.2090, 28.6328), 4326), '2026-01-09 10:30:00+05:30'),
    
    -- 3. Isolated bus stand along outer arterial loop
    ('e1000003-0000-0000-0000-000000000003', 'Eve Teasing & Intimidation', 6, '2026-01-12 20:30:00+05:30', ST_SetSRID(ST_MakePoint(77.2341, 28.6210), 4326), '2026-01-13 09:00:00+05:30'),
    
    -- 4. Industrial boundary road with malfunctioning streetlights
    ('e1000004-0000-0000-0000-000000000004', 'Chain Snatching on Two-Wheeler', 8, '2026-01-14 19:40:00+05:30', ST_SetSRID(ST_MakePoint(77.1952, 28.5804), 4326), '2026-01-15 11:20:00+05:30'),
    
    -- 5. Unmonitored metro station rear exit
    ('e1000005-0000-0000-0000-000000000005', 'Aggressive Stalking', 8, '2026-01-18 22:50:00+05:30', ST_SetSRID(ST_MakePoint(77.2140, 28.5678), 4326), '2026-01-19 07:45:00+05:30'),
    
    -- 6. Deserted park perimeter lane
    ('e1000006-0000-0000-0000-000000000006', 'Attempted Kidnapping / Threat', 10, '2026-01-22 01:10:00+05:30', ST_SetSRID(ST_MakePoint(77.2260, 28.5490), 4326), '2026-01-22 09:15:00+05:30'),
    
    -- 7. Service lane with blind corners
    ('e1000007-0000-0000-0000-000000000007', 'Phone Snatching & Coercion', 6, '2026-01-25 18:25:00+05:30', ST_SetSRID(ST_MakePoint(77.2005, 28.5350), 4326), '2026-01-26 12:00:00+05:30'),
    
    -- 8. Construction detour bypass
    ('e1000008-0000-0000-0000-000000000008', 'Lurking & Indecent Exposure', 7, '2026-01-28 22:15:00+05:30', ST_SetSRID(ST_MakePoint(77.2450, 28.5280), 4326), '2026-01-29 08:30:00+05:30'),
    
    -- 9. Desolate university back road
    ('e1000009-0000-0000-0000-000000000009', 'Verbal Abuse & Tailgating', 5, '2026-02-01 21:05:00+05:30', ST_SetSRID(ST_MakePoint(77.1702, 28.5412), 4326), '2026-02-02 10:10:00+05:30'),
    
    -- 10. Low-visibility bridge footway
    ('e1000010-0000-0000-0000-000000000010', 'Robbery & Physical Intimidation', 9, '2026-02-04 23:20:00+05:30', ST_SetSRID(ST_MakePoint(77.2515, 28.5625), 4326), '2026-02-05 06:50:00+05:30')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. SEED DATA - 15 CROWDSOURCED STREET SAFETY RATINGS
-- Mixed ratings reflecting well-lit commercial zones vs poorly-lit suburban stretches
-- ----------------------------------------------------------------------------
INSERT INTO safety_ratings (id, user_id, street_name, lighting_score, crowd_density, safety_score, location, recorded_at)
VALUES
    -- 1. Inner Circle Boulevard (Well-lit commercial hub, high security)
    ('f1000001-0000-0000-0000-000000000001', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Inner Circle Connaught Place', 5, 5, 5, ST_SetSRID(ST_MakePoint(77.2195, 28.6315), 4326), '2026-02-05 20:00:00+05:30'),
    
    -- 2. Barakhamba Service Corridor (Dimly lit post office hours)
    ('f1000002-0000-0000-0000-000000000002', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Barakhamba Rear Service Lane', 2, 1, 2, ST_SetSRID(ST_MakePoint(77.2270, 28.6280), 4326), '2026-02-05 21:15:00+05:30'),
    
    -- 3. Janpath Market Walkway (High foot traffic, moderate lighting)
    ('f1000003-0000-0000-0000-000000000003', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Janpath Pedestrian Promenade', 4, 4, 4, ST_SetSRID(ST_MakePoint(77.2180, 28.6250), 4326), '2026-02-06 19:45:00+05:30'),
    
    -- 4. Lodhi Colony Art District (Moderate lighting, serene, sporadic patrols)
    ('f1000004-0000-0000-0000-000000000004', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Lodhi Road Block 14 Avenue', 3, 2, 3, ST_SetSRID(ST_MakePoint(77.2240, 28.5890), 4326), '2026-02-06 21:30:00+05:30'),
    
    -- 5. AIIMS Ring Road Subway Entry (Active surveillance, high crowd)
    ('f1000005-0000-0000-0000-000000000005', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Sri Aurobindo Marg Transit Crossing', 4, 5, 4, ST_SetSRID(ST_MakePoint(77.2085, 28.5680), 4326), '2026-02-07 18:20:00+05:30'),
    
    -- 6. South Extension Ring Road Service Alley (Broken streetlights, isolated)
    ('f1000006-0000-0000-0000-000000000006', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'South Extension I Rear By-lane', 1, 1, 1, ST_SetSRID(ST_MakePoint(77.2225, 28.5710), 4326), '2026-02-07 22:40:00+05:30'),
    
    -- 7. Hauz Khas Village Approach Road (Active nightlife, well-lit, steady traffic)
    ('f1000007-0000-0000-0000-000000000007', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Hauz Khas Village Main Gate Road', 4, 4, 4, ST_SetSRID(ST_MakePoint(77.1950, 28.5535), 4326), '2026-02-08 23:10:00+05:30'),
    
    -- 8. Deer Park Boundary Perimeter (Pitch dark at night, no CCTV)
    ('f1000008-0000-0000-0000-000000000008', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Deer Park West Outer Pathway', 1, 1, 1, ST_SetSRID(ST_MakePoint(77.1890, 28.5510), 4326), '2026-02-08 22:00:00+05:30'),
    
    -- 9. Malviya Nagar Market Central Spine (Buzzing market, safe environment)
    ('f1000009-0000-0000-0000-000000000009', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Malviya Nagar Main Commercial Street', 5, 5, 5, ST_SetSRID(ST_MakePoint(77.2070, 28.5385), 4326), '2026-02-09 20:15:00+05:30'),
    
    -- 10. Saket Press Enclave Road (Broad avenue, operational street lamps, frequent PCR vans)
    ('f1000010-0000-0000-0000-000000000010', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Press Enclave Marg Saket', 4, 3, 4, ST_SetSRID(ST_MakePoint(77.2155, 28.5270), 4326), '2026-02-09 21:50:00+05:30'),
    
    -- 11. Khirki Village Internal Arterial (Dense, narrow, inconsistent lighting)
    ('f1000011-0000-0000-0000-000000000011', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Khirki Extension Lane 4', 2, 3, 2, ST_SetSRID(ST_MakePoint(77.2190, 28.5310), 4326), '2026-02-10 20:30:00+05:30'),
    
    -- 12. Nehru Place Outer Plaza Ring (Wide boulevard, active street vendors)
    ('f1000012-0000-0000-0000-000000000012', 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44', 'Nehru Place Bus Terminal Ring', 4, 4, 4, ST_SetSRID(ST_MakePoint(77.2510, 28.5485), 4326), '2026-02-10 19:10:00+05:30'),
    
    -- 13. Okhla Phase III Link Road (Desolate industrial stretch after sunset)
    ('f1000013-0000-0000-0000-000000000013', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Okhla Estate Marg Connector', 2, 1, 2, ST_SetSRID(ST_MakePoint(77.2690, 28.5390), 4326), '2026-02-11 22:15:00+05:30'),
    
    -- 14. Greater Kailash M-Block Outer Boulevard (High socioeconomic safety, private security)
    ('f1000014-0000-0000-0000-000000000014', 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'GK 1 M-Block Market Peripheral Road', 5, 4, 5, ST_SetSRID(ST_MakePoint(77.2360, 28.5560), 4326), '2026-02-11 20:45:00+05:30'),
    
    -- 15. Chirag Dilli Flyover Underpass (Blind curve, shadow pockets)
    ('f1000015-0000-0000-0000-000000000015', 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Chirag Dilli Flyover Lower Crossing', 2, 2, 2, ST_SetSRID(ST_MakePoint(77.2300, 28.5410), 4326), '2026-02-12 21:00:00+05:30')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERY EXAMPLES (For Backend / ML Microservice Integration)
-- ============================================================================
-- Example 1: Query Crime Hotspots within 1,000 meters of a candidate coordinate:
-- SELECT id, crime_type, severity_score, ST_AsText(location) AS geom_wkt,
--        ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(77.2195, 28.6315), 4326)::geography) AS dist_meters
-- FROM crime_hotspots
-- WHERE ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(77.2195, 28.6315), 4326)::geography, 1000)
-- ORDER BY dist_meters ASC;
--
-- Example 2: Aggregated safety score along a corridor:
-- SELECT street_name, AVG(lighting_score) AS avg_light, AVG(crowd_density) AS avg_crowd, AVG(safety_score) AS avg_safety
-- FROM safety_ratings
-- WHERE ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(77.2195, 28.6315), 4326)::geography, 1500)
-- GROUP BY street_name;
-- ============================================================================
