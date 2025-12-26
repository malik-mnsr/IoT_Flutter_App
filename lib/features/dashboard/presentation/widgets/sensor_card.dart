import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';

class SensorCard extends StatelessWidget {
  final double lightPercentage;
  final int adcValue;
  final double voltage;
  final bool ledState;
  final double threshold;

  const SensorCard({
    Key? key,
    required this.lightPercentage,
    required this.adcValue,
    required this.voltage,
    required this.ledState,
    this.threshold = 1000.0,
  }) : super(key: key);

  Color _getLightColor(double percentage) {
    if (percentage < 25) return Colors.red;
    if (percentage < 50) return Colors.orange;
    if (percentage < 75) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getVoltageColor(double voltage) {
    if (voltage < 1.0) return Colors.red;
    if (voltage < 2.0) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Données du capteur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Light Level
            _buildSensorRow(
              icon: Icons.light_mode_outlined,
              label: 'Niveau de lumière',
              value: AppFormatters.formatPercentage(lightPercentage),
              color: _getLightColor(lightPercentage),
              progress: lightPercentage / 100,
            ),

            const SizedBox(height: 20),

            // ADC Value
            Row(
              children: [
                Expanded(
                  child: _buildSensorBox(
                    icon: Icons.speed_outlined,
                    label: 'Valeur ADC',
                    value: AppFormatters.formatAdcValue(adcValue),
                    unit: 'ADC',
                    color: adcValue < threshold ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildSensorBox(
                    icon: Icons.flash_on_outlined,
                    label: 'Tension',
                    value: AppFormatters.formatVoltage(voltage),
                    unit: 'V',
                    color: _getVoltageColor(voltage),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Threshold Indicator
            _buildThresholdIndicator(),

            const SizedBox(height: 20),

            // LED Status
            _buildLedStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              '${progress * 100}%',
              style: TextStyle(fontSize: 10, color: color),
            ),
            Text(
              '100%',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorBox({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.split(' ')[0],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdIndicator() {
    final isBelowThreshold = adcValue < threshold;
    final thresholdPercentage = (threshold / 4095) * 100;
    final currentPercentage = (adcValue / 4095) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seuil d\'allumage automatique',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            Positioned(
              left: 0,
              child: Container(
                height: 30,
                width: (adcValue / 4095) * 300, // Assuming max width of 300
                decoration: BoxDecoration(
                  color: isBelowThreshold ? Colors.orange : Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            Positioned(
              left: (threshold / 4095) * 300 - 2,
              child: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '${threshold.toInt()} ADC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 ADC',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              '${threshold.toInt()} ADC',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '4095 ADC',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBelowThreshold ? Colors.orange[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBelowThreshold ? Colors.orange[100]! : Colors.blue[100]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isBelowThreshold ? Icons.warning_amber : Icons.check_circle,
                color: isBelowThreshold ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBelowThreshold
                      ? 'En dessous du seuil - LED allumée automatiquement'
                      : 'Au-dessus du seuil - LED éteinte',
                  style: TextStyle(
                    color: isBelowThreshold ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLedStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ledState ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ledState ? Colors.green[100]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ledState ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ledState ? Icons.lightbulb : Icons.lightbulb_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ledState ? 'LED Allumée' : 'LED Éteinte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ledState ? Colors.green[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ledState
                      ? 'La LED est actuellement allumée'
                      : 'La LED est actuellement éteinte',
                  style: TextStyle(
                    color: ledState ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ledState ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ledState ? 'ON' : 'OFF',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}