import 'package:flutter/material.dart';

/// Widget para mostrar información detallada de la ruta en tiempo real
class RideInfoPanel extends StatelessWidget {
  final double? progress;
  final double? distanceRemaining;
  final Duration? estimatedTime;
  final double? speed;
  final String? driverName;
  final String? vehicleInfo;
  final VoidCallback? onClose;
  final VoidCallback? onContact;
  final VoidCallback? onCancel;

  const RideInfoPanel({
    super.key,
    this.progress,
    this.distanceRemaining,
    this.estimatedTime,
    this.speed,
    this.driverName,
    this.vehicleInfo,
    this.onClose,
    this.onContact,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معلومات الرحلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (progress != null) _buildProgressBar(progress!),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.location_on,
            title: 'المسافة المتبقية',
            value: distanceRemaining != null
                ? '${distanceRemaining!.toStringAsFixed(1)} كم'
                : 'غير معروف',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.access_time,
            title: 'الوقت المقدر للوصول',
            value: estimatedTime != null
                ? '${estimatedTime!.inMinutes} دقيقة'
                : 'غير معروف',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.speed,
            title: 'السرعة الحالية',
            value: speed != null ? '${speed!.toStringAsFixed(0)} كم/ساعة' : 'غير معروف',
          ),
          if (driverName != null || vehicleInfo != null) const Divider(height: 32),
          if (driverName != null)
            _buildInfoRow(
              icon: Icons.person,
              title: 'السائق',
              value: driverName!,
            ),
          if (vehicleInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildInfoRow(
                icon: Icons.directions_car,
                title: 'المركبة',
                value: vehicleInfo!,
              ),
            ),
          if (onContact != null || onCancel != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onContact != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text('اتصال'),
                      onPressed: onContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (onCancel != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('إلغاء الرحلة'),
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('تقدم الرحلة'),
            Text('${progress.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }
}
