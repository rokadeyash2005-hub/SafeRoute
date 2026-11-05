import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'safety_rating_dialog.dart';

class RouteBottomSheet extends StatelessWidget {
  const RouteBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final rec = navProvider.routeRecommendation;

    if (rec == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF00E676), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'AI RECOMMENDED SAFEST ROUTE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: () => navProvider.clearRoute(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Summary
          Text(
            rec.routeSummary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Safety Metric Grid Cards
          Row(
            children: [
              // Star Rating Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${rec.safetyRating.toStringAsFixed(1)} / 5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Safety Rating',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Composite Risk Score Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            rec.compositeRiskScore < 4.0 ? Icons.shield_rounded : Icons.warning_amber_rounded,
                            color: rec.compositeRiskScore < 4.0 ? const Color(0xFF00E676) : Colors.orangeAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rec.compositeRiskScore.toStringAsFixed(1)} / 10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Risk Score',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Distance / ETA Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rec.formattedDistance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.estimatedWalkingTime,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              // Crowdsource rate button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Rate Street', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const SafetyRatingDialog(),
                  );
                },
              ),
              const SizedBox(width: 10),

              // Primary "Start Safe Navigation" button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navProvider.isNavigating
                        ? Colors.redAccent
                        : const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: Icon(
                    navProvider.isNavigating ? Icons.stop_rounded : Icons.navigation_rounded,
                    color: navProvider.isNavigating ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    navProvider.isNavigating ? 'Stop Navigation' : 'Start Safe Navigation',
                    style: TextStyle(
                      color: navProvider.isNavigating ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    if (navProvider.isNavigating) {
                      navProvider.stopNavigation();
                    } else {
                      navProvider.startNavigation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF00C853),
                          content: Text('Safe Navigation Started. Continuous hazard monitoring active.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
