import 'package:flutter/material.dart';

class RoutePreviewCard extends StatelessWidget {
  final String title;
  final double distance;
  final double duration;
  final IconData icon;
  final Color color;

  const RoutePreviewCard({
    Key? key,
    required this.title,
    required this.distance,
    required this.duration,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km • ${_formatDuration(duration)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    
    if (hours > 0) {
      final remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}