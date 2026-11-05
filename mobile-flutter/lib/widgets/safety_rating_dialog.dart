import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/api_service.dart';

class SafetyRatingDialog extends StatefulWidget {
  const SafetyRatingDialog({super.key});

  @override
  State<SafetyRatingDialog> createState() => _SafetyRatingDialogState();
}

class _SafetyRatingDialogState extends State<SafetyRatingDialog> {
  final _streetController = TextEditingController();
  int _lightingScore = 4;
  int _crowdScore = 3;
  int _safetyScore = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  Widget _buildStarRatingBar(String label, int value, ValueChanged<int> onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.amberAccent),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$value/5', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            return IconButton(
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
              icon: Icon(
                star <= value ? Icons.star_rounded : Icons.star_border_rounded,
                color: star <= value ? Colors.amberAccent : Colors.white24,
              ),
              onPressed: () => onChanged(star),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.read<NavigationProvider>();
    final authProvider = context.read<AuthProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.rate_review_rounded, color: Color(0xFF00E676), size: 24),
          SizedBox(width: 8),
          Text('Rate Current Street', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your telemetry directly powers the ML routing model for women across this neighborhood.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _streetController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Street / Landmark Name',
                hintText: 'e.g. Press Enclave Marg, Block B',
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.add_location_alt_outlined, color: Colors.white54, size: 20),
                filled: true,
                fillColor: const Color(0xFF2C2C3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildStarRatingBar(
              'Street Lighting Quality',
              _lightingScore,
              (v) => setState(() => _lightingScore = v),
              Icons.lightbulb_outline_rounded,
            ),
            _buildStarRatingBar(
              'Crowd Density / Eyes on Street',
              _crowdScore,
              (v) => setState(() => _crowdScore = v),
              Icons.people_alt_outlined,
            ),
            _buildStarRatingBar(
              'Perceived Safety & Comfort',
              _safetyScore,
              (v) => setState(() => _safetyScore = v),
              Icons.shield_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final token = authProvider.currentUser?.token ?? '';
                  final lat = navProvider.currentLocation.latitude;
                  final lng = navProvider.currentLocation.longitude;
                  final street = _streetController.text.trim().isEmpty
                      ? 'Current Street Segment'
                      : _streetController.text.trim();

                  await ApiService.submitSafetyRating(
                    latitude: lat,
                    longitude: lng,
                    streetName: street,
                    lightingScore: _lightingScore,
                    crowdDensity: _crowdScore,
                    safetyScore: _safetyScore,
                    token: token,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF00C853),
                      content: Text('Thank you! Street safety rating recorded in PostGIS.'),
                    ),
                  );
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
