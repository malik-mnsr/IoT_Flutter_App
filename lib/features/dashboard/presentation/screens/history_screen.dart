import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/models/device_model.dart';
import '../../domain/models/sensor_data_model.dart';
import '../widgets/history_chart.dart';
import '../../../../presentation/widgets/loading_widget.dart';

class HistoryScreen extends StatefulWidget {
  final Device device;

  const HistoryScreen({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> _timeRanges = [
    '1 heure',
    '24 heures',
    '7 jours',
    '30 jours',
    'Tout'
  ];
  final List<int> _timeRangeHours = [1, 24, 168, 720, 8760]; // 1 month ~= 720h

  String _selectedTimeRange = '24 heures';
  int _selectedRangeIndex = 1;
  List<SensorData> _sensorData = [];
  bool _isLoading = true;
  bool _showChart = true;
  ChartType _selectedChartType = ChartType.line;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = context.read<DatabaseService>();
      final endDate = DateTime.now();
      final startDate = endDate.subtract(
        Duration(hours: _timeRangeHours[_selectedRangeIndex]),
      );

      _sensorData = await databaseService.getDeviceHistory(
        deviceId: widget.device.id,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de chargement de l\'historique: $e',
      );
      setState(() => _isLoading = false);
    }
  }

  void _onTimeRangeChanged(String? value) {
    if (value == null) return;

    setState(() {
      _selectedTimeRange = value;
      _selectedRangeIndex = _timeRanges.indexOf(value);
    });

    _loadHistory();
  }

  void _toggleView() {
    setState(() => _showChart = !_showChart);
  }

  void _changeChartType(ChartType type) {
    setState(() => _selectedChartType = type);
  }

  Map<String, dynamic> _calculateStats() {
    if (_sensorData.isEmpty) {
      return {
        'avgLight': 0.0,
        'maxLight': 0.0,
        'minLight': 0.0,
        'onTime': 0,
        'dataPoints': 0,
      };
    }

    double totalLight = 0;
    double maxLight = _sensorData.first.lightPercentage;
    double minLight = _sensorData.first.lightPercentage;
    int onTime = 0;

    for (final data in _sensorData) {
      totalLight += data.lightPercentage;
      if (data.lightPercentage > maxLight) maxLight = data.lightPercentage;
      if (data.lightPercentage < minLight) minLight = data.lightPercentage;
      if (data.ledState) onTime++;
    }

    return {
      'avgLight': totalLight / _sensorData.length,
      'maxLight': maxLight,
      'minLight': minLight,
      'onTime': onTime,
      'dataPoints': _sensorData.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: Text('Historique - ${widget.device.name}'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.show_chart),
            onPressed: _toggleView,
            tooltip: _showChart ? 'Voir liste' : 'Voir graphique',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
        children: [
          // Time Range Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Période:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeRange,
                    items: _timeRanges
                        .map((range) => DropdownMenuItem(
                      value: range,
                      child: Text(range),
                    ))
                        .toList(),
                    onChanged: _onTimeRangeChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics Cards
          _buildStatistics(stats),

          // Chart/List View
          Expanded(
            child: _showChart
                ? _buildChartView()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Moyenne',
            value: AppFormatters.formatPercentage(stats['avgLight']),
            icon: Icons.trending_up,
          ),
          _buildStatItem(
            label: 'Max',
            value: AppFormatters.formatPercentage(stats['maxLight']),
            icon: Icons.arrow_upward,
          ),
          _buildStatItem(
            label: 'Min',
            value: AppFormatters.formatPercentage(stats['minLight']),
            icon: Icons.arrow_downward,
          ),
          _buildStatItem(
            label: 'Allumé',
            value: '${stats['onTime']} pts',
            icon: Icons.lightbulb,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChartView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart Type Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: const Text('Ligne'),
                selected: _selectedChartType == ChartType.line,
                onSelected: (selected) =>
                    _changeChartType(ChartType.line),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Barre'),
                selected: _selectedChartType == ChartType.bar,
                onSelected: (selected) =>
                    _changeChartType(ChartType.bar),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Aire'),
                selected: _selectedChartType == ChartType.area,
                onSelected: (selected) =>
                    _changeChartType(ChartType.area),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: HistoryChart(
              sensorData: _sensorData,
              chartType: _selectedChartType,
              timeRange: _selectedTimeRange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_sensorData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune donnée historique',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sensorData.length,
      itemBuilder: (context, index) {
        final data = _sensorData[index];
        return _buildHistoryItem(data);
      },
    );
  }

  Widget _buildHistoryItem(SensorData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: data.ledState ? Colors.amber[50] : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            data.ledState ? Icons.lightbulb : Icons.lightbulb_outline,
            color: data.ledState ? Colors.amber : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                AppFormatters.formatPercentage(data.lightPercentage),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: data.ledState ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: data.ledState ? Colors.green[100]! : Colors.grey[300]!,
                ),
              ),
              child: Text(
                data.ledState ? 'ON' : 'OFF',
                style: TextStyle(
                  color: data.ledState ? Colors.green[700] : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'ADC: ${data.adcValue}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.flash_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${AppFormatters.formatVoltage(data.voltage)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatTimestamp(data.timestamp, showSeconds: true),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}