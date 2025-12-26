import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../presentation/widgets/loading_widget.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../dashboard/domain/models/device_model.dart';
import '../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  List<Device> _devices = [];
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = context.read<AuthService>();
      final databaseService = context.read<DatabaseService>();

      final user = await authService.getCurrentUser();
      if (user == null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
        return;
      }

      setState(() => _currentUser = user);

      // Load user devices
      final devices = await databaseService.getUserDevices(user.uid);
      setState(() => _devices = devices);

    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de chargement: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    // Simplified image picker - without permission_handler
    SnackbarHelper.showInfo(
      context: context,
      message: 'Image picker à configurer avec image_picker',
    );
    
    // TODO: Implement with image_picker package
    // 1. Add image_picker to pubspec.yaml
    // 2. Import image_picker
    // 3. Pick image using ImagePicker()
    // 4. Upload to Firebase Storage
    // 5. Update user profile with new photoUrl
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Erreur de déconnexion: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Stack(
                      children: [
                        ProfileAvatar(
                          photoUrl: _currentUser!.photoUrl,
                          name: _currentUser!.name,
                          email: _currentUser!.email,
                          size: 100,
                          editable: true,
                          onTap: _changeProfilePicture,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentUser!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.email,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user: _currentUser!),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
            ],
          ),

          // Profile Content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // Quick Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          value: _devices.length.toString(),
                          label: 'Appareils',
                          icon: Icons.devices,
                          color: Colors.blue,
                        ),
                        _buildStatItem(
                          value: _devices.where((d) => d.isOnline).length.toString(),
                          label: 'En ligne',
                          icon: Icons.wifi,
                          color: Colors.green,
                        ),
                        _buildStatItem(
                          value: AppFormatters.dateFormatter.format(_currentUser!.createdAt),
                          label: 'Membre depuis',
                          icon: Icons.calendar_today,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Personal Information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: _currentUser!.email,
                        ),
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Nom',
                          value: _currentUser!.name ?? 'Non renseigné',
                        ),
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Téléphone',
                          value: _currentUser!.phoneNumber ?? 'Non renseigné',
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Localisation',
                          value: _currentUser!.location ?? 'Non renseignée',
                        ),
                        _buildInfoRow(
                          icon: Icons.verified,
                          label: 'Email vérifié',
                          value: _currentUser!.emailVerified ? 'Oui' : 'Non',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // My Devices
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Mes appareils',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/dashboard',
                                      (route) => false,
                                );
                              },
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_devices.isEmpty)
                          const Center(
                            child: Text(
                              'Aucun appareil configuré',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          Column(
                            children: _devices
                                .take(3)
                                .map((device) => _buildDeviceItem(device))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Account Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions du compte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          icon: Icons.security,
                          label: 'Sécurité',
                          onTap: () {},
                        ),
                        const Divider(),
                        _buildActionButton(
                          icon: Icons.notifications,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        const Divider(),
                        _buildActionButton(
                          icon: Icons.privacy_tip,
                          label: 'Confidentialité',
                          onTap: () {},
                        ),
                        const Divider(),
                        _buildActionButton(
                          icon: Icons.help,
                          label: 'Aide & Support',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutConfirmation,
                    icon: const Icon(Icons.logout),
                    label: const Text('Déconnexion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
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
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(Device device) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: device.statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          device.icon,
          color: device.statusColor,
          size: 20,
        ),
      ),
      title: Text(device.name),
      subtitle: Text(
        '${device.ipAddress} • ${device.statusText}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/device-control',
          arguments: device,
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}