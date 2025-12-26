import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/device_model.dart';
import '../widgets/control_panel.dart';
import '../widgets/sensor_card.dart';
import '../../../../presentation/widgets/loading_widget.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late Device _device;
  Map<String, dynamic>? _sensorData;
  bool _isLoading = false;
  bool _isOnline = false;
  double _threshold = 1000.0;
  final TextEditingController _thresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _threshold = _device.threshold;
    _thresholdController.text = _threshold.toStringAsFixed(0);
    _startMonitoring();
  }

  void _startMonitoring() {
    final sensorService = context.read<SensorService>();

    sensorService.startMonitoring(
      _device.id,
      _device.ipAddress,
    );

    sensorService.getDeviceStream(_device.id).listen((data) {
      if (mounted) {
        setState(() {
          _sensorData = data;
          _isOnline = data['isOnline'] ?? false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    });
  }

  Future<void> _controlLed(String command) async {
    try {
      final sensorService = context.read<SensorService>();

      switch (command) {
        case 'toggle':
          await sensorService.toggleLed(_device.id);
          break;
        case 'on':
          await sensorService.turnOnLed(_device.id);
          break;
        case 'off':
          await sensorService.turnOffLed(_device.id);
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

  Future<void> _updateThreshold() async {
    final threshold = double.tryParse(_thresholdController.text);
    if (threshold == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Valeur de seuil invalide',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sensorService = context.read<SensorService>();
      await sensorService.updateDeviceSettings(_device.id, threshold);

      // Update local device
      final updatedDevice = _device.copyWith(threshold: threshold);
      setState(() => _device = updatedDevice);

      // Update in database
      final databaseService = context.read<DatabaseService>();
      await databaseService.updateDevice(updatedDevice);

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Seuil mis à jour à ${threshold.toInt()}',
      );
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de mise à jour: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateDeviceName(String newName) async {
    if (newName.trim().isEmpty || newName == _device.name) return;

    setState(() => _isLoading = true);

    try {
      final updatedDevice = _device.copyWith(name: newName.trim());
      final databaseService = context.read<DatabaseService>();
      await databaseService.updateDevice(updatedDevice);

      setState(() => _device = updatedDevice);

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Nom de l\'appareil mis à jour',
      );
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de mise à jour: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showThresholdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le seuil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Définir la valeur de seuil pour l\'allumage automatique',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Seuil (0-4095)',
                suffixText: 'ADC',
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateThreshold,
            ),
            const SizedBox(height: 8),
            Text(
              'Valeur actuelle: ${_threshold.toInt()} ADC',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateThreshold();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _device.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer l\'appareil'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'appareil',
            border: OutlineInputBorder(),
          ),
          validator: Validators.validateDeviceName,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _updateDeviceName(controller.text.trim());
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showRenameDialog,
            tooltip: 'Renommer',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showThresholdDialog,
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Device Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.wifi : Icons.wifi_off,
                          color: _isOnline ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _device.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _device.ipAddress,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'Localisation',
                          value: _device.location ?? 'Non définie',
                        ),
                        _buildInfoItem(
                          icon: Icons.speed_outlined,
                          label: 'Seuil',
                          value: '${_device.threshold.toInt()} ADC',
                        ),
                        _buildInfoItem(
                          icon: Icons.update,
                          label: 'Dernière vue',
                          value: AppFormatters.formatRelativeTime(
                            _device.lastSeen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sensor Data
            if (_sensorData != null && _isOnline)
              SensorCard(
                lightPercentage: _sensorData!['lightPercentage'] ?? 0.0,
                adcValue: _sensorData!['adcValue'] ?? 0,
                voltage: _sensorData!['voltage'] ?? 0.0,
                ledState: _sensorData!['ledState'] ?? false,
                threshold: _device.threshold,
              )
            else
              _buildOfflineState(),

            const SizedBox(height: 20),

            // Control Panel
            ControlPanel(
              ledState: _sensorData?['ledState'] ?? false,
              deviceOnline: _isOnline,
              onToggle: () => _controlLed('toggle'),
              onOn: () => _controlLed('on'),
              onOff: () => _controlLed('off'),
              showExtended: true,
            ),

            const SizedBox(height: 20),

            // Auto Control Settings
            _buildAutoControlSettings(),

            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
            'Impossible de se connecter à ${_device.ipAddress}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoControlSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contrôle automatique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'La LED s\'allume automatiquement lorsque la luminosité descend en dessous du seuil.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seuil actuel',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_device.threshold.toInt()} ADC',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showThresholdDialog,
                  child: const Text('Modifier'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _sensorData != null
                  ? (_sensorData!['adcValue'] ?? 0) / 4095
                  : 0.5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _sensorData != null && (_sensorData!['adcValue'] ?? 0) < _device.threshold
                    ? Colors.orange
                    : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 ADC',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${_device.threshold.toInt()} ADC',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '4095 ADC',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (_sensorData != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_sensorData!['adcValue'] ?? 0) < _device.threshold
                      ? Colors.orange[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_sensorData!['adcValue'] ?? 0) < _device.threshold
                        ? Colors.orange[100]!
                        : Colors.blue[100]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_sensorData!['adcValue'] ?? 0) < _device.threshold
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      color: (_sensorData!['adcValue'] ?? 0) < _device.threshold
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (_sensorData!['adcValue'] ?? 0) < _device.threshold
                            ? 'LED allumée (luminosité basse)'
                            : 'LED éteinte (luminosité suffisante)',
                        style: TextStyle(
                          color: (_sensorData!['adcValue'] ?? 0) < _device.threshold
                              ? Colors.orange[800]
                              : Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: const Text('Rafraîchir'),
                  onPressed: () {
                    final sensorService = context.read<SensorService>();
                    sensorService.refreshDevice(_device.id);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: const Text('Historique'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/history',
                      arguments: _device,
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Détails'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/device-details',
                      arguments: _device,
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Supprimer'),
                  backgroundColor: Colors.red[50],
                  onPressed: _showDeleteConfirmation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'appareil'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet appareil ? '
              'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDevice();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = context.read<DatabaseService>();
      final authService = context.read<AuthService>();
      final currentUser = await authService.getCurrentUser();

      if (currentUser != null) {
        await databaseService.deleteDevice(_device.id, currentUser.uid);

        // Stop monitoring
        final sensorService = context.read<SensorService>();
        sensorService.stopMonitoring(_device.id);

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Appareil supprimé avec succès',
        );

        Navigator.pop(context); // Retour au dashboard
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de suppression: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }
}