import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ControlPanel extends StatelessWidget {
  final bool ledState;
  final bool deviceOnline;
  final VoidCallback onToggle;
  final VoidCallback onOn;
  final VoidCallback onOff;
  final VoidCallback? onSettings;
  final VoidCallback? onHistory;
  final bool showExtended;

  const ControlPanel({
    Key? key,
    required this.ledState,
    required this.deviceOnline,
    required this.onToggle,
    required this.onOn,
    required this.onOff,
    this.onSettings,
    this.onHistory,
    this.showExtended = false,
  }) : super(key: key);

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
              'Contrôle manuel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (!deviceOnline)
              _buildOfflineWarning(),

            if (deviceOnline) ...[
              // Main Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.power_settings_new,
                    label: 'Basculer',
                    color: Colors.blue,
                    onPressed: onToggle,
                  ),
                  _buildControlButton(
                    icon: Icons.power,
                    label: 'Allumer',
                    color: Colors.green,
                    onPressed: onOn,
                  ),
                  _buildControlButton(
                    icon: Icons.power_off,
                    label: 'Éteindre',
                    color: Colors.red,
                    onPressed: onOff,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // LED Status Indicator
              _buildLedIndicator(),

              if (showExtended) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Extended Controls
                _buildExtendedControls(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Appareil hors ligne - Contrôle désactivé',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, size: 30, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLedIndicator() {
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ledState ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: ledState
                  ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
                  : null,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ledState ? Colors.green[800] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ledState
                      ? 'État actuel: Activée'
                      : 'État actuel: Désactivée',
                  style: TextStyle(
                    color: ledState ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: ledState,
            onChanged: (value) => onToggle(),
            activeColor: Colors.green,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions supplémentaires',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (onSettings != null)
              ActionChip(
                avatar: const Icon(Icons.settings, size: 18),
                label: const Text('Paramètres'),
                onPressed: onSettings,
              ),
            if (onHistory != null)
              ActionChip(
                avatar: const Icon(Icons.history, size: 18),
                label: const Text('Historique'),
                onPressed: onHistory,
              ),
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Rafraîchir'),
              onPressed: onToggle, // Reuse toggle for refresh
            ),
            ActionChip(
              avatar: const Icon(Icons.info_outline, size: 18),
              label: const Text('Infos'),
              onPressed: () {},
            ),
            ActionChip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: const Text('Programmer'),
              onPressed: () {},
            ),
            ActionChip(
              avatar: const Icon(Icons.notification_important, size: 18),
              label: const Text('Alertes'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Status
        Row(
          children: [
            _buildStatusChip(
              icon: Icons.wifi,
              label: 'En ligne',
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            _buildStatusChip(
              icon: Icons.lightbulb_outline,
              label: ledState ? 'Allumé' : 'Éteint',
              color: ledState ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 10),
            _buildStatusChip(
              icon: Icons.security,
              label: 'Sécurisé',
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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
    );
  }
}