import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/device_model.dart';
import '../widgets/sensor_card.dart';
import '../widgets/control_panel.dart';
import '../widgets/device_card.dart';

import '../../../../presentation/widgets/loading_widget.dart';
import '../../../../presentation/widgets/empty_state.dart';

import '../../../../presentation/widgets/error_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RefreshController _refreshController = RefreshController();
  UserModel? _currentUser;
  List<Device> _devices = [];
  Device? _selectedDevice;
  Map<String, dynamic>? _sensorData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final databaseService = context.read<DatabaseService>();
      final authService = context.read<AuthService>();

      // Get current user
      _currentUser = await authService.getCurrentUser();

      if (_currentUser == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
        return;
      }

      // Get user devices
      _devices = await databaseService.getUserDevices(_currentUser!.uid);

      if (_devices.isNotEmpty) {
        _selectedDevice = _devices.first;
        _startDeviceMonitoring();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de chargement: $e',
      );
    }
  }

  void _startDeviceMonitoring() {
    if (_selectedDevice == null) return;

    final sensorService = context.read<SensorService>();

    // Stop previous monitoring
    for (final device in _devices) {
      if (sensorService.isMonitoring(device.id)) {
        sensorService.stopMonitoring(device.id);
      }
    }

    // Start monitoring selected device
    sensorService.startMonitoring(
      _selectedDevice!.id,
      _selectedDevice!.ipAddress,
    );

    // Listen for sensor updates
    sensorService.getDeviceStream(_selectedDevice!.id).listen((data) {
      if (mounted) {
        setState(() => _sensorData = data);
      }
    }, onError: (error) {
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Erreur de capteur: $error',
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      if (_selectedDevice != null) {
        final sensorService = context.read<SensorService>();
        await sensorService.refreshDevice(_selectedDevice!.id);
      }

      await _loadData();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de rafraîchissement: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _selectDevice(Device device) {
    setState(() => _selectedDevice = device);
    _startDeviceMonitoring();
  }

  void _addNewDevice() {
    Navigator.pushNamed(context, '/add-device').then((_) => _loadData());
  }

  void _viewDeviceSettings() {
    if (_selectedDevice == null) return;

    Navigator.pushNamed(
      context,
      '/device-settings',
      arguments: _selectedDevice!,
    ).then((_) => _loadData());
  }

  void _viewHistory() {
    if (_selectedDevice == null) return;

    Navigator.pushNamed(
      context,
      '/history',
      arguments: _selectedDevice!,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tableau de bord')),
        body: CustomErrorWidget(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewDevice,
            tooltip: 'Ajouter un appareil',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        enablePullDown: true,
        enablePullUp: false,
        header: const ClassicHeader(
          idleText: 'Tirer pour rafraîchir',
          releaseText: 'Relâcher pour rafraîchir',
          refreshingText: 'Rafraîchissement...',
          completeText: 'Rafraîchi',
          failedText: 'Échec',
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_devices.isEmpty) {
      return EmptyState(
        icon: Icons.devices_outlined,
        title: 'Aucun appareil',
        message: 'Ajoutez votre premier appareil ESP32 pour commencer',
        actionText: 'Ajouter un appareil',
        onAction: _addNewDevice,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Selector
          _buildDeviceSelector(),
          const SizedBox(height: 20),

          // Device Status
          if (_selectedDevice != null)
            _buildDeviceStatus(),

          const SizedBox(height: 20),

          // Sensor Data
          if (_sensorData != null && _sensorData!['isOnline'] == true)
            SensorCard(
              lightPercentage: _sensorData!['lightPercentage'] ?? 0.0,
              adcValue: _sensorData!['adcValue'] ?? 0,
              voltage: _sensorData!['voltage'] ?? 0.0,
              ledState: _sensorData!['ledState'] ?? false,
              threshold: _sensorData!['threshold'] ?? 0.0,
            )
          else
            _buildOfflineState(),

          const SizedBox(height: 20),

          // Control Panel
          if (_selectedDevice != null && _sensorData != null)
            ControlPanel(
              ledState: _sensorData!['ledState'] ?? false,
              deviceOnline: _sensorData!['isOnline'] ?? false,
              onToggle: () => _controlLed('toggle'),
              onOn: () => _controlLed('on'),
              onOff: () => _controlLed('off'),
              onSettings: _viewDeviceSettings,
              onHistory: _viewHistory,
            ),

          const SizedBox(height: 20),

          // Quick Stats
          if (_currentUser != null)
            _buildQuickStats(),

          const SizedBox(height: 20),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appareils',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _devices.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _devices.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: DeviceCard.add(
                    onTap: _addNewDevice,
                  ),
                );
              }

              final device = _devices[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: 10,
                  left: index == 0 ? 0 : 0,
                ),
                child: DeviceCard(
                  device: device,
                  isSelected: _selectedDevice?.id == device.id,
                  onTap: () => _selectDevice(device),
                  onLongPress: () {
                    Navigator.pushNamed(
                      context,
                      '/device-details',
                      arguments: device,
                    ).then((_) => _loadData());
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceStatus() {
    final isOnline = _sensorData?['isOnline'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: isOnline ? Colors.green[100]! : Colors.red[100]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDevice!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: isOnline ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isOnline) ...[
                  const SizedBox(height: 4),
                  Text(
                    _selectedDevice!.ipAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isOnline)
            TextButton(
              onPressed: _onRefresh,
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Appareil hors ligne',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de récupérer les données du capteur',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onRefresh,
            child: const Text('Réessayer la connexion'),
          ),
        ],
      ),
    );
  }

  Future<void> _controlLed(String command) async {
    if (_selectedDevice == null) return;

    try {
      final sensorService = context.read<SensorService>();

      switch (command) {
        case 'toggle':
          await sensorService.toggleLed(_selectedDevice!.id);
          break;
        case 'on':
          await sensorService.turnOnLed(_selectedDevice!.id);
          break;
        case 'off':
          await sensorService.turnOffLed(_selectedDevice!.id);
          break;
      }

      SnackbarHelper.showSuccess(
        context: context,
        message: 'LED ${command == 'on' ? 'allumée' : command == 'off' ? 'éteinte' : 'basculée'}',
      );
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de contrôle: $e',
      );
    }
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatItem(
                  icon: Icons.devices,
                  label: 'Appareils',
                  value: _devices.length.toString(),
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.online_prediction,
                  label: 'En ligne',
                  value: _devices.where((d) => d.isOnline).length.toString(),
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.timer,
                  label: 'Activité',
                  value: '${_currentUser!.deviceCount}',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.leaderboard,
                  label: 'Données',
                  value: '${_sensorData != null ? 'Actives' : 'N/A'}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activité récente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_sensorData != null && _sensorData!['isOnline'] == true)
              Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.lightbulb_outline,
                    title: 'État LED',
                    subtitle: _sensorData!['ledState'] ? 'Allumée' : 'Éteinte',
                    time: 'Maintenant',
                    color: _sensorData!['ledState'] ? Colors.amber : Colors.grey,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.light_mode_outlined,
                    title: 'Luminosité',
                    subtitle: '${(_sensorData!['lightPercentage'] ?? 0).toStringAsFixed(1)}%',
                    time: 'Maintenant',
                    color: Colors.blue,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.speed_outlined,
                    title: 'Valeur ADC',
                    subtitle: '${_sensorData!['adcValue'] ?? 0}',
                    time: 'Maintenant',
                    color: Colors.green,
                  ),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Aucune activité récente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            if (_sensorData != null && _sensorData!['isOnline'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _viewHistory,
                    child: const Text('Voir l\'historique complet'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    // Stop all monitoring when leaving dashboard
    final sensorService = context.read<SensorService>();
    sensorService.stopAllMonitoring();
    super.dispose();
  }
}