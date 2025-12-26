import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteNames {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Dashboard Routes
  static const String dashboard = '/dashboard';
  static const String deviceControl = '/device-control';
  static const String history = '/history';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  // Settings Routes
  static const String settings = '/settings';
  static const String deviceSettings = '/device-settings';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';
  static const String securitySettings = '/security-settings';

  // Device Management Routes
  static const String addDevice = '/add-device';
  static const String deviceDetails = '/device-details';
  static const String editDevice = '/edit-device';
  static const String scanDevice = '/scan-device';

  // Help & Support Routes
  static const String help = '/help';
  static const String faq = '/faq';
  static const String contact = '/contact';
  static const String about = '/about';
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  // Data & Analytics Routes
  static const String analytics = '/analytics';
  static const String reports = '/reports';
  static const String exportData = '/export-data';

  // Other Routes
  static const String home = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String maintenance = '/maintenance';
  static const String error = '/error';
  static const String offline = '/offline';
  static const String deepLink = '/deeplink';

  // Tab Routes (for bottom navigation)
  static const String devicesTab = '/devices';
  static const String controlTab = '/control';
  static const String historyTab = '/history-tab';
  static const String profileTab = '/profile-tab';

  // Modal Routes
  static const String addDeviceModal = '/add-device-modal';
  static const String editDeviceModal = '/edit-device-modal';
  static const String deviceInfoModal = '/device-info-modal';
  static const String thresholdModal = '/threshold-modal';
  static const String scheduleModal = '/schedule-modal';
  static const String notificationModal = '/notification-modal';

  // API Test Routes
  static const String apiTest = '/api-test';
  static const String deviceTest = '/device-test';
  static const String sensorTest = '/sensor-test';

  // Utility method to get all routes
  static List<String> getAllRoutes() {
    return [
      login,
      register,
      forgotPassword,
      dashboard,
      deviceControl,
      history,
      profile,
      editProfile,
      settings,
      deviceSettings,
      notificationSettings,
      privacySettings,
      securitySettings,
      addDevice,
      deviceDetails,
      editDevice,
      scanDevice,
      help,
      faq,
      contact,
      about,
      terms,
      privacy,
      analytics,
      reports,
      exportData,
      home,
      splash,
      onboarding,
      maintenance,
      error,
      offline,
      deepLink,
      devicesTab,
      controlTab,
      historyTab,
      profileTab,
      addDeviceModal,
      editDeviceModal,
      deviceInfoModal,
      thresholdModal,
      scheduleModal,
      notificationModal,
      apiTest,
      deviceTest,
      sensorTest,
    ];
  }

  // Check if route is public (no authentication required)
  static bool isPublicRoute(String routeName) {
    final publicRoutes = [
      login,
      register,
      forgotPassword,
      splash,
      onboarding,
      offline,
      error,
      terms,
      privacy,
      about,
    ];
    return publicRoutes.contains(routeName);
  }

  // Check if route is modal/dialog
  static bool isModalRoute(String routeName) {
    final modalRoutes = [
      addDeviceModal,
      editDeviceModal,
      deviceInfoModal,
      thresholdModal,
      scheduleModal,
      notificationModal,
    ];
    return modalRoutes.contains(routeName);
  }

  // Get route title for display
  static String getRouteTitle(String routeName) {
    final titles = {
      login: 'Connexion',
      register: 'Inscription',
      forgotPassword: 'Mot de passe oublié',
      dashboard: 'Tableau de bord',
      deviceControl: 'Contrôle d\'appareil',
      history: 'Historique',
      profile: 'Profil',
      editProfile: 'Modifier le profil',
      settings: 'Paramètres',
      deviceSettings: 'Paramètres de l\'appareil',
      notificationSettings: 'Notifications',
      privacySettings: 'Confidentialité',
      securitySettings: 'Sécurité',
      addDevice: 'Ajouter un appareil',
      deviceDetails: 'Détails de l\'appareil',
      editDevice: 'Modifier l\'appareil',
      scanDevice: 'Scanner un appareil',
      help: 'Aide',
      faq: 'FAQ',
      contact: 'Contact',
      about: 'À propos',
      terms: 'Conditions d\'utilisation',
      privacy: 'Politique de confidentialité',
      analytics: 'Analytiques',
      reports: 'Rapports',
      exportData: 'Exporter les données',
      home: 'Accueil',
      splash: 'Chargement',
      onboarding: 'Bienvenue',
      maintenance: 'Maintenance',
      error: 'Erreur',
      offline: 'Hors ligne',
      deepLink: 'Lien profond',
      devicesTab: 'Appareils',
      controlTab: 'Contrôle',
      historyTab: 'Historique',
      profileTab: 'Profil',
    };
    return titles[routeName] ?? 'Page';
  }

  // Get route icon for navigation
  static IconData? getRouteIcon(String routeName) {
    final icons = {
      dashboard: Icons.dashboard,
      deviceControl: Icons.devices,
      history: Icons.history,
      profile: Icons.person,
      settings: Icons.settings,
      addDevice: Icons.add,
      help: Icons.help,
      about: Icons.info,
      devicesTab: Icons.devices_outlined,
      controlTab: Icons.toggle_on_outlined,
      historyTab: Icons.timeline_outlined,
      profileTab: Icons.person_outline,
    };
    return icons[routeName];
  }

  // Get route for deep linking
  static String? getRouteForDeepLink(Uri uri) {
    // Handle deep links like: myapp://device/control?id=123
    final path = uri.path;
    final queryParams = uri.queryParameters;

    switch (path) {
      case '/device/control':
        final deviceId = queryParams['id'];
        if (deviceId != null) {
          // Return a route that can handle device control
          return deviceControl;
        }
        break;
      case '/dashboard':
        return dashboard;
      case '/profile':
        return profile;
    // Add more deep link handlers as needed
    }

    return null;
  }

  // Parse route parameters from URI
  static Map<String, dynamic>? parseRouteParameters(String routeName, Uri uri) {
    final queryParams = uri.queryParameters;

    switch (routeName) {
      case deviceControl:
        return {'deviceId': queryParams['id']};
      case history:
        return {
          'deviceId': queryParams['id'],
          'period': queryParams['period'] ?? '24h',
        };
    // Add more parameter parsers as needed
    }

    return null;
  }

  // Check if route requires specific permissions
  static List<String>? getRequiredPermissions(String routeName) {
    final permissions = {
      deviceSettings: ['manage_devices'],
      analytics: ['view_analytics'],
      exportData: ['export_data'],
      // Add more permission requirements
    };
    return permissions[routeName];
  }

  // Get route category for organization
  static String getRouteCategory(String routeName) {
    if (routeName.startsWith('/device')) {
      return 'devices';
    } else if (routeName.startsWith('/auth') ||
        routeName.contains('login') ||
        routeName.contains('register') ||
        routeName.contains('password')) {
      return 'auth';
    } else if (routeName.contains('settings') ||
        routeName.contains('profile')) {
      return 'settings';
    } else if (routeName.contains('help') ||
        routeName.contains('about') ||
        routeName.contains('terms') ||
        routeName.contains('privacy')) {
      return 'help';
    } else if (routeName.contains('history') ||
        routeName.contains('analytics') ||
        routeName.contains('reports')) {
      return 'analytics';
    } else if (routeName.contains('modal') ||
        routeName.contains('dialog')) {
      return 'modals';
    }
    return 'general';
  }

  // Get all routes by category
  static Map<String, List<String>> getAllRoutesByCategory() {
    final categories = <String, List<String>>{};

    for (final route in getAllRoutes()) {
      final category = getRouteCategory(route);
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(route);
    }

    return categories;
  }

  // Validate route name
  static bool isValidRoute(String routeName) {
    return getAllRoutes().contains(routeName);
  }

  // Get default route based on authentication status
  static String getDefaultRoute(bool isAuthenticated) {
    return isAuthenticated ? dashboard : login;
  }
}