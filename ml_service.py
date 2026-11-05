"""
Crowdsourced Real-Time Women Safety and Safe-Route Recommendation System (MCA-P17)
ML Microservice: Spatial Polyline Segmentation, PostGIS Risk Scoring & Route Optimization

Framework: FastAPI + PostGIS + SQLAlchemy
Port: 8082
Endpoints:
  - GET  /health
  - POST /api/ml/evaluate-routes
"""

import os
import math
import logging
from datetime import datetime, timezone
from typing import List, Optional, Tuple, Dict, Any

import numpy as np
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.pool import QueuePool

# -----------------------------------------------------------------------------
# 1. LOGGING & APPLICATION INITIALIZATION
# -----------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s]: %(message)s"
)
logger = logging.getLogger("MCA-P17-ML-Engine")

app = FastAPI(
    title="SafeRoute AI - Microservice (MCA-P17)",
    description="Proactive Safe-Route Recommendation Engine evaluating spatial crime data, crowdsourced safety ratings, and time-of-day variables.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------------------------------------------------------
# 2. DATABASE CONFIGURATION & CONNECTION POOLING
# -----------------------------------------------------------------------------
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")
DB_HOST = os.getenv("POSTGRES_SERVER", os.getenv("POSTGRES_HOST", "localhost"))
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "saferoute_db")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

db_engine: Optional[Engine] = None

try:
    test_engine = create_engine(
        DATABASE_URL,
        poolclass=QueuePool,
        pool_size=10,
        max_overflow=20,
        pool_recycle=1800,
        pool_pre_ping=True,
        connect_args={"connect_timeout": 2}
    )
    with test_engine.connect() as conn:
        logger.info("Successfully connected to PostGIS: %s:%s/%s", DB_HOST, DB_PORT, DB_NAME)
    db_engine = test_engine
except Exception as ex:
    logger.warning("PostGIS database not reachable at %s:%s (%s). Running in standalone heuristic mode.", DB_HOST, DB_PORT, str(ex))
    db_engine = None


# -----------------------------------------------------------------------------
# 3. PYDANTIC SCHEMAS (DATA TRANSFER OBJECTS)
# -----------------------------------------------------------------------------
class Coordinate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude in WGS 84")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude in WGS 84")


class RouteCandidate(BaseModel):
    route_id: Optional[str] = Field(default=None, description="Optional route identifier from Spring Boot gateway")
    summary: Optional[str] = Field(default=None, description="Route summary / road names (e.g. via Ring Road)")
    coordinates: List[Coordinate] = Field(..., min_length=2, description="Polyline vertices in sequential order")
    total_distance_meters: Optional[float] = Field(default=None, description="Total road distance provided by routing engine")


class RouteEvaluationRequest(BaseModel):
    destination: Coordinate = Field(..., description="User destination point")
    origin: Optional[Coordinate] = Field(default=None, description="User origin point")
    departure_time: Optional[datetime] = Field(
        default=None, 
        description="Departure timestamp (ISO 8601). Defaults to current server UTC time if omitted."
    )
    routes: List[RouteCandidate] = Field(..., min_length=1, description="List of candidate routes to be scored")
    
    # Tunable cost model parameters with defaults specified in MCA-P17 specs
    w1_crime: float = Field(default=0.40, ge=0.0, le=1.0, description="Weight for crime severity score")
    w2_crowd: float = Field(default=0.25, ge=0.0, le=1.0, description="Weight for crowd density deficit")
    w3_lighting: float = Field(default=0.25, ge=0.0, le=1.0, description="Weight for lighting deficit")
    w4_time: float = Field(default=0.10, ge=0.0, le=1.0, description="Weight for time-of-day risk factor")
    alpha_distance: float = Field(default=0.001, ge=0.0, description="Linear penalty multiplier per meter traveled")


class SegmentAnalysis(BaseModel):
    segment_index: int
    coordinate: Coordinate
    crime_score: float
    lighting_score: float
    crowd_score: float
    lighting_deficit: float
    crowd_deficit: float
    time_factor: float
    raw_segment_cost: float
    nearby_crimes_count: int
    nearby_ratings_count: int
    is_cold_start: bool


class EvaluatedRouteDetail(BaseModel):
    route_index: int
    route_id: Optional[str] = None
    summary: Optional[str] = None
    total_distance_meters: float
    total_cost: float
    composite_risk_score: float  # Normalized 1.0 (safest) to 10.0 (hazardous)
    safety_rating: float          # 1.0 (poor) to 5.0 (optimal) stars
    sampled_points_count: int
    detailed_segment_analysis: List[SegmentAnalysis]


class RouteEvaluationResponse(BaseModel):
    status: str
    safest_route_index: int
    recommended_polyline: List[Coordinate]
    composite_risk_score: float
    safety_rating: float
    total_evaluated_routes: int
    detailed_segment_analysis: List[SegmentAnalysis]
    all_evaluated_routes: List[EvaluatedRouteDetail]


class HealthResponse(BaseModel):
    status: str
    database_connected: bool
    timestamp: datetime
    active_database: str


# -----------------------------------------------------------------------------
# 4. GEODESIC MATHEMATICS & POLYLINE SAMPLING
# -----------------------------------------------------------------------------
def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Computes great-circle distance between two WGS 84 coordinates in meters.
    """
    earth_radius_m = 6371000.0  # Earth mean radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2))
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return earth_radius_m * c


def sample_polyline(coordinates: List[Coordinate], step_meters: float = 50.0) -> List[Coordinate]:
    """
    Discretizes and resamples a polyline at ~50-meter intervals.
    Maintains start and end points and interpolates along segment vectors.
    """
    if not coordinates:
        return []
    if len(coordinates) == 1:
        return [coordinates[0]]

    sampled_points: List[Coordinate] = [coordinates[0]]

    for i in range(len(coordinates) - 1):
        p1 = coordinates[i]
        p2 = coordinates[i + 1]

        segment_length = haversine_distance(p1.latitude, p1.longitude, p2.latitude, p2.longitude)
        if segment_length < 1e-4:
            continue

        num_steps = max(1, int(round(segment_length / step_meters)))

        for step in range(1, num_steps + 1):
            fraction = float(step) / float(num_steps)
            lat_interp = p1.latitude + fraction * (p2.latitude - p1.latitude)
            lon_interp = p1.longitude + fraction * (p2.longitude - p1.longitude)
            sampled_points.append(Coordinate(latitude=lat_interp, longitude=lon_interp))

    return sampled_points


# -----------------------------------------------------------------------------
# 5. TEMPORAL RISK & SPATIAL POSTGIS QUERY LOGIC
# -----------------------------------------------------------------------------
def calculate_time_factor(dep_time: datetime) -> float:
    """
    Evaluates temporal vulnerability factor (scale 1.0 to 10.0).
    Nighttime and early dawn hours escalate vulnerability due to reduced natural surveillance.
    """
    hour = dep_time.hour + (dep_time.minute / 60.0)

    if 22.0 <= hour or hour < 4.5:
        # High-risk midnight to deep night
        return 10.0
    elif 4.5 <= hour < 6.5:
        # Dawn transition
        return 5.5
    elif 6.5 <= hour < 17.5:
        # Daytime: highest natural visibility and passive pedestrian presence
        return 1.5
    elif 17.5 <= hour < 20.0:
        # Dusk / evening peak transit
        return 4.5
    else:
        # 20.0 to 22.0: Late evening transition
        return 7.5


def get_temporal_cold_start_defaults(dep_time: datetime) -> Tuple[float, float]:
    """
    Cold-start fallback for streets with zero crowdsourced telemetry.
    Returns (default_lighting_score, default_crowd_score) on 1-5 scale.
    """
    hour = dep_time.hour
    if 22 <= hour or hour < 5:
        return (2.0, 1.5)  # Dim baseline, sparse crowd
    elif 5 <= hour < 7:
        return (3.0, 2.5)
    elif 7 <= hour < 18:
        return (4.5, 4.0)  # Bright daylight, moderate to active crowd
    elif 18 <= hour < 21:
        return (3.5, 3.5)
    else:
        return (2.5, 2.0)


def execute_spatial_lookups(
    lat: float, 
    lon: float, 
    buffer_radius_m: float = 200.0
) -> Tuple[float, int, Optional[float], Optional[float], int]:
    """
    Executes spatial aggregation queries using PostGIS ST_DWithin over a 200m buffer.
    Returns:
      (crime_score, nearby_crimes_count, avg_lighting, avg_crowd, nearby_ratings_count)
    """
    if db_engine is None:
        # Graceful degradation if running standalone without PostgreSQL
        return 0.0, 0, None, None, 0

    crime_sql = text("""
        SELECT 
            COUNT(id) AS crime_count,
            COALESCE(
                SUM(
                    severity_score * (1.0 - (ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / :radius))
                ), 
                0.0
            ) AS weighted_crime_score
        FROM crime_hotspots
        WHERE ST_DWithin(
            location::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radius
        );
    """)

    rating_sql = text("""
        SELECT 
            COUNT(id) AS rating_count,
            AVG(lighting_score) AS avg_lighting,
            AVG(crowd_density) AS avg_crowd
        FROM safety_ratings
        WHERE ST_DWithin(
            location::geography,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radius
        );
    """)

    try:
        with db_engine.connect() as conn:
            # Query crime hotspots
            crime_res = conn.execute(crime_sql, {"lat": lat, "lon": lon, "radius": buffer_radius_m}).fetchone()
            crimes_count = int(crime_res[0]) if crime_res else 0
            weighted_crime_score = float(crime_res[1]) if crime_res else 0.0

            # Query crowdsourced telemetry
            rating_res = conn.execute(rating_sql, {"lat": lat, "lon": lon, "radius": buffer_radius_m}).fetchone()
            ratings_count = int(rating_res[0]) if rating_res else 0
            avg_lighting = float(rating_res[1]) if rating_res and rating_res[1] is not None else None
            avg_crowd = float(rating_res[2]) if rating_res and rating_res[2] is not None else None

            # Normalizing crime score: clamp between 0.0 and 10.0
            crime_score = min(10.0, max(0.0, weighted_crime_score))

            return crime_score, crimes_count, avg_lighting, avg_crowd, ratings_count

    except Exception as err:
        logger.error("Spatial PostGIS query error at (lat=%f, lon=%f): %s", lat, lon, str(err))
        return 0.0, 0, None, None, 0


# -----------------------------------------------------------------------------
# 6. ROUTE EVALUATION & RISK COST ENGINE
# -----------------------------------------------------------------------------
def evaluate_single_route(
    route_index: int,
    route: RouteCandidate,
    departure_dt: datetime,
    w1: float,
    w2: float,
    w3: float,
    w4: float,
    alpha: float
) -> EvaluatedRouteDetail:
    """
    Samples polyline at ~50m intervals, performs 200m buffer PostGIS queries,
    applies cold-start fallbacks, and computes the mathematical cost:
      Cost(Route) = SUM(segment_cost) + alpha * Total_Distance
    """
    # 1. Sample polyline
    sampled_coords = sample_polyline(route.coordinates, step_meters=50.0)
    
    # 2. Compute total road distance
    total_dist_meters = 0.0
    for i in range(len(route.coordinates) - 1):
        total_dist_meters += haversine_distance(
            route.coordinates[i].latitude, route.coordinates[i].longitude,
            route.coordinates[i + 1].latitude, route.coordinates[i + 1].longitude
        )
    
    if route.total_distance_meters is not None and route.total_distance_meters > 0:
        total_dist_meters = route.total_distance_meters

    # 3. Time factor for departure time
    time_factor = calculate_time_factor(departure_dt)
    default_lighting, default_crowd = get_temporal_cold_start_defaults(departure_dt)

    segment_analyses: List[SegmentAnalysis] = []
    cumulative_segment_cost = 0.0

    for idx, pt in enumerate(sampled_coords):
        crime_score, crimes_count, avg_lighting, avg_crowd, ratings_count = execute_spatial_lookups(
            pt.latitude, pt.longitude, buffer_radius_m=200.0
        )

        is_cold_start = (ratings_count == 0)

        # Crowdsourced metrics or cold-start fallback
        lighting_score = avg_lighting if avg_lighting is not None else default_lighting
        crowd_score = avg_crowd if avg_crowd is not None else default_crowd

        # Deficit calculation: Scale is 1 (poor) to 5 (excellent)
        # Low lighting/crowd escalates vulnerability deficit
        lighting_deficit = max(0.0, 5.0 - lighting_score)
        crowd_deficit = max(0.0, 5.0 - crowd_score)

        # Risk cost for current segment:
        # segment_cost = w1 * CrimeScore + w2 * (5 - CrowdRating) + w3 * LightingDeficit + w4 * TimeFactor
        raw_segment_cost = (
            (w1 * crime_score) +
            (w2 * crowd_deficit) +
            (w3 * lighting_deficit) +
            (w4 * time_factor)
        )

        cumulative_segment_cost += raw_segment_cost

        segment_analyses.append(
            SegmentAnalysis(
                segment_index=idx,
                coordinate=pt,
                crime_score=round(crime_score, 2),
                lighting_score=round(lighting_score, 2),
                crowd_score=round(crowd_score, 2),
                lighting_deficit=round(lighting_deficit, 2),
                crowd_deficit=round(crowd_deficit, 2),
                time_factor=round(time_factor, 2),
                raw_segment_cost=round(raw_segment_cost, 4),
                nearby_crimes_count=crimes_count,
                nearby_ratings_count=ratings_count,
                is_cold_start=is_cold_start
            )
        )

    # Total route cost function:
    # Cost(Route) = SUM(segment_cost) + alpha * Total_Distance
    distance_penalty = alpha * total_dist_meters
    total_route_cost = cumulative_segment_cost + distance_penalty

    # Composite risk normalization: 1.0 (Safest) to 10.0 (Severe Risk)
    num_pts = max(1, len(sampled_coords))
    avg_segment_cost = cumulative_segment_cost / num_pts
    
    # Baseline expected max segment cost is ~5.0 with normal weights.
    normalized_risk = min(10.0, max(1.0, (avg_segment_cost / 4.0) * 9.0 + 1.0))

    # Star rating: 1.0 to 5.0
    safety_stars = round(max(1.0, min(5.0, 5.5 - (normalized_risk * 0.45))), 1)

    return EvaluatedRouteDetail(
        route_index=route_index,
        route_id=route.route_id or f"candidate_route_{route_index}",
        summary=route.summary or f"Route {route_index + 1}",
        total_distance_meters=round(total_dist_meters, 2),
        total_cost=round(total_route_cost, 4),
        composite_risk_score=round(normalized_risk, 2),
        safety_rating=safety_stars,
        sampled_points_count=num_pts,
        detailed_segment_analysis=segment_analyses
    )


# -----------------------------------------------------------------------------
# 7. FASTAPI API ENDPOINTS
# -----------------------------------------------------------------------------
@app.get("/health", response_model=HealthResponse, tags=["Monitoring"])
def health_check():
    """
    Liveness and Readiness probe inspecting PostGIS spatial database connectivity.
    """
    db_connected = False
    if db_engine is not None:
        try:
            with db_engine.connect() as conn:
                res = conn.execute(text("SELECT PostGIS_Version();")).fetchone()
                if res:
                    db_connected = True
        except Exception as e:
            logger.warning("Health check PostGIS ping failed: %s", str(e))
            db_connected = False

    return HealthResponse(
        status="healthy" if db_connected else "degraded",
        database_connected=db_connected,
        timestamp=datetime.now(timezone.utc),
        active_database=DB_NAME
    )


@app.post(
    "/api/ml/evaluate-routes",
    response_model=RouteEvaluationResponse,
    status_code=status.HTTP_200_OK,
    tags=["Safe-Route Recommendation Engine"]
)
def evaluate_routes(request: RouteEvaluationRequest):
    """
    Main Route Recommendation Engine Endpoint:
    Receives candidate polylines from Spring Boot orchestrator, samples each polyline,
    runs localized PostGIS ST_DWithin aggregations, scores environmental and temporal
    deficits, and returns the safest route with full segment diagnostics.
    """
    if not request.routes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one candidate route must be provided for safety evaluation."
        )

    departure_dt = request.departure_time or datetime.now(timezone.utc)
    evaluated_routes: List[EvaluatedRouteDetail] = []

    logger.info("Evaluating %d candidate route(s) at departure time %s", len(request.routes), departure_dt)

    for idx, candidate in enumerate(request.routes):
        evaluated = evaluate_single_route(
            route_index=idx,
            route=candidate,
            departure_dt=departure_dt,
            w1=request.w1_crime,
            w2=request.w2_crowd,
            w3=request.w3_lighting,
            w4=request.w4_time,
            alpha=request.alpha_distance
        )
        evaluated_routes.append(evaluated)

    # Pick route with lowest total cost (safest route)
    safest_route = min(evaluated_routes, key=lambda r: r.total_cost)
    recommended_polyline = request.routes[safest_route.route_index].coordinates

    logger.info(
        "Optimal Route Identified: Index %d | Total Cost: %.4f | Risk Score: %.2f | Stars: %.1f",
        safest_route.route_index,
        safest_route.total_cost,
        safest_route.composite_risk_score,
        safest_route.safety_rating
    )

    return RouteEvaluationResponse(
        status="success",
        safest_route_index=safest_route.route_index,
        recommended_polyline=recommended_polyline,
        composite_risk_score=safest_route.composite_risk_score,
        safety_rating=safest_route.safety_rating,
        total_evaluated_routes=len(evaluated_routes),
        detailed_segment_analysis=safest_route.detailed_segment_analysis,
        all_evaluated_routes=evaluated_routes
    )


# -----------------------------------------------------------------------------
# 8. DIRECT SCRIPT ENTRYPOINT (UVICORN RUNNER)
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    server_port = int(os.getenv("PORT", "8082"))
    logger.info("Starting SafeRoute AI Microservice on port %d...", server_port)
    uvicorn.run(app, host="0.0.0.0", port=server_port)
