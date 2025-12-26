import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/device_control_screen.dart';
import '../../features/dashboard/presentation/screens/history_screen.dart';
import '../../features/dashboard/domain/models/device_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../widgets/loading_widget.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
    // Auth Routes
      case RouteNames.login:
        return _buildRoute(settings, const LoginScreen());

      case RouteNames.register:
        return _buildRoute(settings, const RegisterScreen());

      case RouteNames.forgotPassword:
        return _buildRoute(settings, const ForgotPasswordScreen());

    // Dashboard Routes
      case RouteNames.dashboard:
        return _buildRoute(settings, const DashboardScreen());

      case RouteNames.deviceControl:
        if (args == null || args is! Device) {
          return _errorRoute('Device argument is required');
        }
        return _buildRoute(settings, DeviceControlScreen(device: args as Device));

      case RouteNames.history:
        if (args == null || args is! Device) {
          return _errorRoute('Device argument is required');
        }
        return _buildRoute(settings, HistoryScreen(device: args as Device));

    // Profile Routes
      case RouteNames.profile:
        return _buildRoute(settings, const ProfileScreen());

      case RouteNames.editProfile:
        if (args == null || args is! UserModel) {
          return _errorRoute('User argument is required');
        }
        return _buildRoute(settings, EditProfileScreen(user: args as UserModel));

    // Settings Routes
      case RouteNames.settings:
        return _buildRoute(settings, _buildPlaceholder('Settings'));

      case RouteNames.deviceSettings:
        return _buildRoute(settings, _buildPlaceholder('Device Settings'));

    // Help Routes
      case RouteNames.help:
        return _buildRoute(settings, _buildPlaceholder('Help'));

      case RouteNames.about:
        return _buildRoute(settings, _buildPlaceholder('About'));

    // Add Device Route
      case RouteNames.addDevice:
        return _buildRoute(settings, _buildPlaceholder('Add Device'));

      case RouteNames.deviceDetails:
        return _buildRoute(settings, _buildPlaceholder('Device Details'));

    // Default route
      default:
        return _errorRoute('Route ${settings.name} not found');
    }
  }

  // Authentication wrapper for protected routes
  static Widget _authWrapper(Widget child, BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoading(message: 'Vérification...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          // Redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.login,
                  (route) => false,
            );
          });
          return const FullScreenLoading(message: 'Redirection...');
        }
      },
    );
  }

  // Build route with transitions
  static MaterialPageRoute _buildRoute(RouteSettings settings, Widget screen) {
    return MaterialPageRoute(
      builder: (context) => screen,
      settings: settings,
    );
  }

  // Error route
  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }

  // Placeholder screen
  static Widget _buildPlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 60,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 20),
            Text(
              '$title - En construction',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cette fonctionnalité sera bientôt disponible',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate back
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  // Route generator with authentication check
  Route<dynamic> onGenerateRouteWithAuth(RouteSettings settings) {
    // Define public routes that don't require authentication
    final publicRoutes = [
      RouteNames.login,
      RouteNames.register,
      RouteNames.forgotPassword,
    ];

    // Check if route requires authentication
    if (!publicRoutes.contains(settings.name)) {
      final route = onGenerateRoute(settings);
      if (route is MaterialPageRoute) {
        return MaterialPageRoute(
          builder: (context) => _authWrapper(
            route.builder(context),
            context,
          ),
          settings: settings,
        );
      }
    }

    return onGenerateRoute(settings);
  }

  // Navigation methods
  static void navigateToLogin(BuildContext context, {bool replace = false}) {
    if (replace) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
            (route) => false,
      );
    } else {
      Navigator.pushNamed(context, RouteNames.login);
    }
  }

  static void navigateToDashboard(BuildContext context, {bool replace = false}) {
    if (replace) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.dashboard,
            (route) => false,
      );
    } else {
      Navigator.pushNamed(context, RouteNames.dashboard);
    }
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.profile);
  }

  static void navigateToDeviceControl(BuildContext context, dynamic device) {
    Navigator.pushNamed(
      context,
      RouteNames.deviceControl,
      arguments: device,
    );
  }

  static void navigateToHistory(BuildContext context, dynamic device) {
    Navigator.pushNamed(
      context,
      RouteNames.history,
      arguments: device,
    );
  }

  // Check current route
  static String getCurrentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name ?? '';
  }

  // Check if current route is auth route
  static bool isAuthRoute(BuildContext context) {
    final currentRoute = getCurrentRoute(context);
    return currentRoute == RouteNames.login ||
        currentRoute == RouteNames.register ||
        currentRoute == RouteNames.forgotPassword;
  }

  // Get route arguments
  static dynamic getRouteArguments(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments;
  }

  // Pop to specific route
  static void popToRoute(BuildContext context, String routeName) {
    Navigator.popUntil(context, (route) => route.settings.name == routeName);
  }

  // Clear navigation stack and go to route
  static void clearStackAndGoTo(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
          (route) => false,
    );
  }
}

/// Route observer for analytics
class RouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _history = [];

  List<Route<dynamic>> get history => List.unmodifiable(_history);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _history.add(route);
    _logRouteChange('Pushed', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    _logRouteChange('Popped', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_history.isNotEmpty && oldRoute != null) {
      final index = _history.indexOf(oldRoute);
      if (index != -1 && newRoute != null) {
        _history[index] = newRoute;
      }
    }
    _logRouteChange('Replaced', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _history.remove(route);
    _logRouteChange('Removed', route, previousRoute);
  }

  void _logRouteChange(String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final current = route?.settings.name ?? 'Unknown';
    final previous = previousRoute?.settings.name ?? 'None';

    print('$action: $previous -> $current');
    // Here you can add analytics tracking
    // Analytics.trackScreenView(current);
  }

  String getCurrentRouteName() {
    if (_history.isEmpty) return '';
    return _history.last.settings.name ?? '';
  }

  bool isOnRoute(String routeName) {
    return getCurrentRouteName() == routeName;
  }

  void clearHistory() {
    _history.clear();
  }
}

/// Route guard for specific roles
class RoleRouteGuard {
  final Map<String, List<String>> _rolePermissions = {
    RouteNames.dashboard: ['user', 'admin'],
    RouteNames.deviceSettings: ['admin'],
    // Add more route permissions as needed
  };

  bool hasPermission(String routeName, String userRole) {
    final allowedRoles = _rolePermissions[routeName];
    if (allowedRoles == null) {
      // Route doesn't have specific permissions
      return true;
    }
    return allowedRoles.contains(userRole);
  }
}