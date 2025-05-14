import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/models/route_model.dart';
import '../services/ride_prediction_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/route_preview_card.dart';

class RideMatchingScreen extends StatefulWidget {
  final RouteModel originalRoute;
  final RouteModel newRoute;
  final RouteModel riderRoute;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideMatchingScreen({
    Key? key,
    required this.originalRoute,
    required this.newRoute,
    required this.riderRoute,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  State<RideMatchingScreen> createState() => _RideMatchingScreenState();
}

class _RideMatchingScreenState extends State<RideMatchingScreen> {
  bool _isLoading = false;
  bool _isGoodMatch = false;
  double _matchScore = 0.0;
  RouteModel get _originalRoute => widget.originalRoute;
  RouteModel get _newRoute => widget.newRoute;
  RouteModel get _riderRoute => widget.riderRoute;

  @override
  void initState() {
    super.initState();
    _checkRideMatch();
  }

  Future<void> _checkRideMatch() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prediction =
          await RidePredictionService.instance.predictRideSharing(
        originalDistance: _originalRoute.distance,
        distanceAfterAddingRider: _newRoute.distance,
        newRiderDistance: _riderRoute.distance,
      );

      // تصحيح الوصول إلى البيانات بناءً على هيكل الاستجابة
      final shouldAddRider = prediction['prediction']['add_rider'] == 1;
      final score = prediction['prediction']['prediction_score'];

      setState(() {
        _isLoading = false;
        _matchScore = score;
        _isGoodMatch = shouldAddRider;
      });

      _showMatchResult();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check ride match: $e')),
      );
    }
  }

  void _showMatchResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _isGoodMatch ? 'Good Match!' : 'Not Recommended',
          style: TextStyle(
            color: _isGoodMatch ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isGoodMatch
                  ? 'This rider is a good match for your route!'
                  : 'Adding this rider may significantly increase your travel time.',
            ),
            const SizedBox(height: 16),
            Text(
              'Match Score: ${(_matchScore * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _getScoreColor(_matchScore),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Match Analysis'),
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingView() : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SpinKitDoubleBounce(
            color: AppColors.primary,
            size: 50.0,
          ),
          SizedBox(height: 24),
          Text(
            'Analyzing route compatibility...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRouteComparison(),
          const SizedBox(height: 24),
          _buildMatchScoreCard(),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRouteComparison() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RoutePreviewCard(
              title: 'Your Original Route',
              distance: _originalRoute.distance,
              duration: _originalRoute.duration,
              icon: Icons.directions_car,
              color: AppColors.primary,
            ),
            const Divider(),
            RoutePreviewCard(
              title: 'Route With Rider',
              distance: _newRoute.distance,
              duration: _newRoute.duration,
              icon: Icons.people,
              color: AppColors.secondary,
            ),
            const Divider(),
            _buildRouteStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStats() {
    final distanceDifference = _newRoute.distance - _originalRoute.distance;
    final durationDifference = _newRoute.duration - _originalRoute.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Distance: ${distanceDifference.toStringAsFixed(1)} km',
          style: TextStyle(
            color: distanceDifference > 5 ? AppColors.error : AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Additional Time: ${(durationDifference / 60).toStringAsFixed(0)} minutes',
          style: TextStyle(
            color: durationDifference > 15 * 60
                ? AppColors.error
                : AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchScoreCard() {
    return Card(
      elevation: 4,
      color: _getScoreColor(_matchScore).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Match Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: _getScoreColor(_matchScore),
              child: Text(
                '${(_matchScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isGoodMatch
                  ? 'This is a good match for your route!'
                  : 'This match is not recommended.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(_matchScore),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            onPressed: () {
              widget.onReject();
              Navigator.of(context).pop();
            },
            text: 'Decline',
            backgroundColor: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            onPressed: () {
              widget.onAccept();
              Navigator.of(context).pop();
            },
            text: 'Accept',
            backgroundColor:
                _isGoodMatch ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }
}
