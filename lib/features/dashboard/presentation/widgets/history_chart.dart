import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/sensor_data_model.dart';

enum ChartType { line, bar, area }

class HistoryChart extends StatelessWidget {
  final List<SensorData> sensorData;
  final ChartType chartType;
  final String timeRange;

  const HistoryChart({
    Key? key,
    required this.sensorData,
    this.chartType = ChartType.line,
    required this.timeRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sensorData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune donnée à afficher',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SfCartesianChart(
      title: ChartTitle(text: 'Historique des données'),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        format: 'point.x\npoint.y%',
        canShowMarker: true,
      ),
      primaryXAxis: DateTimeAxis(
        title: AxisTitle(text: 'Temps'),
        dateFormat: DateFormat(_getDateFormatString()),
        intervalType: _getIntervalType(),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Luminosité (%)'),
        minimum: 0,
        maximum: 100,
        interval: 20,
        labelFormat: '{value}%',
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      series: _getChartSeries(),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        enableSelectionZooming: true,
        selectionRectBorderColor: Colors.red,
        selectionRectColor: Colors.red.withOpacity(0.1),
      ),
    );
  }

  String _getDateFormatString() {
    switch (timeRange) {
      case '1 heure':
        return 'HH:mm';
      case '24 heures':
        return 'HH:mm';
      case '7 jours':
        return 'dd/MM HH:mm';
      case '30 jours':
        return 'dd/MM';
      case 'Tout':
        return 'MM/yyyy';
      default:
        return 'dd/MM HH:mm';
    }
  }

  DateTimeIntervalType _getIntervalType() {
    switch (timeRange) {
      case '1 heure':
        return DateTimeIntervalType.minutes;
      case '24 heures':
        return DateTimeIntervalType.hours;
      case '7 jours':
        return DateTimeIntervalType.days;
      case '30 jours':
        return DateTimeIntervalType.days;
      case 'Tout':
        return DateTimeIntervalType.months;
      default:
        return DateTimeIntervalType.hours;
    }
  }

  List<CartesianSeries<SensorData, DateTime>> _getChartSeries() {
    final sortedData = List<SensorData>.from(sensorData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    switch (chartType) {
      case ChartType.line:
        return [
          LineSeries<SensorData, DateTime>(
            name: 'Luminosité',
            dataSource: sortedData,
            xValueMapper: (data, _) => data.timestamp,
            yValueMapper: (data, _) => data.lightPercentage,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.blue,
            width: 2,
          ),
          LineSeries<SensorData, DateTime>(
            name: 'LED',
            dataSource: sortedData,
            xValueMapper: (data, _) => data.timestamp,
            yValueMapper: (data, _) => data.ledState ? 100 : 0,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.amber,
            width: 2,
            dashArray: [5, 5],
          ),
        ];

      case ChartType.bar:
        return [
          BarSeries<SensorData, DateTime>(
            name: 'Luminosité',
            dataSource: sortedData,
            xValueMapper: (data, _) => data.timestamp,
            yValueMapper: (data, _) => data.lightPercentage,
            color: Colors.blue,
            spacing: 0.1,
          ),
        ];

      case ChartType.area:
        return [
          AreaSeries<SensorData, DateTime>(
            name: 'Luminosité',
            dataSource: sortedData,
            xValueMapper: (data, _) => data.timestamp,
            yValueMapper: (data, _) => data.lightPercentage,
            color: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            borderWidth: 2,
          ),
        ];
    }
  }
}

// Alternative: Simple chart with Flutter native charts
class SimpleHistoryChart extends StatelessWidget {
  final List<SensorData> sensorData;

  const SimpleHistoryChart({
    Key? key,
    required this.sensorData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedData = List<SensorData>.from(sensorData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution de la luminosité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _ChartPainter(sortedData),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Luminosité'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.amber, 'État LED'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SensorData> data;

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final ledPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Find min and max values
    double minLight = double.infinity;
    double maxLight = -double.infinity;
    DateTime minTime = data.first.timestamp;
    DateTime maxTime = data.last.timestamp;

    for (final point in data) {
      if (point.lightPercentage < minLight) minLight = point.lightPercentage;
      if (point.lightPercentage > maxLight) maxLight = point.lightPercentage;
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw data points
    Path lightPath = Path();
    Path ledPath = Path();

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = padding +
          (point.timestamp.difference(minTime).inMilliseconds /
              maxTime.difference(minTime).inMilliseconds) *
              chartWidth;
      final y = padding +
          chartHeight -
          ((point.lightPercentage - minLight) / (maxLight - minLight)) *
              chartHeight;

      if (i == 0) {
        lightPath.moveTo(x, y);
      } else {
        lightPath.lineTo(x, y);
      }

      // Draw LED state as dots
      if (point.ledState) {
        canvas.drawCircle(Offset(x, size.height - padding), 4, ledPaint);
      }
    }

    canvas.drawPath(lightPath, paint);

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}