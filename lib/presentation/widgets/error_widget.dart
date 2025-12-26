import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/colors.dart';

/// Custom error widget with multiple styles
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final ErrorType type;
  final Widget? customIcon;
  final EdgeInsetsGeometry padding;
  final bool showDetails;
  final bool showActionButtons;

  const CustomErrorWidget({
    Key? key,
    required this.message,
    this.details,
    this.onRetry,
    this.type = ErrorType.generic,
    this.customIcon,
    this.padding = const EdgeInsets.all(20),
    this.showDetails = false,
    this.showActionButtons = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(theme),
          const SizedBox(height: 20),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (details != null && showDetails) ...[
            const SizedBox(height: 12),
            Text(
              details!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (showActionButtons && onRetry != null) ...[
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (customIcon != null) return customIcon!;

    switch (type) {
      case ErrorType.network:
        return Icon(
          Icons.wifi_off_outlined,
          size: 80,
          color: theme.hintColor,
        );
      case ErrorType.server:
        return Icon(
          Icons.cloud_off_outlined,
          size: 80,
          color: theme.colorScheme.error,
        );
      case ErrorType.empty:
        return Icon(
          Icons.search_off_outlined,
          size: 80,
          color: theme.hintColor,
        );
      case ErrorType.permission:
        return Icon(
          Icons.lock_outline,
          size: 80,
          color: theme.hintColor,
        );
      case ErrorType.lottie:
        return SizedBox(
          width: 150,
          height: 150,
          child: Lottie.asset(
            'assets/animations/error.json',
            fit: BoxFit.contain,
          ),
        );
      case ErrorType.generic:
      default:
        return Icon(
          Icons.error_outline_outlined,
          size: 80,
          color: theme.colorScheme.error,
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            // Show error details dialog
            _showErrorDetails(context);
          },
          icon: const Icon(Icons.info_outline),
          label: const Text('Détails'),
        ),
      ],
    );
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'erreur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message: $message'),
            if (details != null) ...[
              const SizedBox(height: 12),
              Text('Détails: $details'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Error types
enum ErrorType {
  generic,
  network,
  server,
  empty,
  permission,
  lottie,
}

/// Full screen error widget
class FullScreenError extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final ErrorType type;
  final Color? backgroundColor;

  const FullScreenError({
    Key? key,
    required this.title,
    required this.message,
    this.onRetry,
    this.type = ErrorType.generic,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(theme),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    switch (type) {
      case ErrorType.network:
        return Icon(
          Icons.wifi_off,
          size: 100,
          color: theme.hintColor,
        );
      case ErrorType.server:
        return Icon(
          Icons.cloud_off,
          size: 100,
          color: theme.colorScheme.error,
        );
      case ErrorType.empty:
        return Icon(
          Icons.search_off,
          size: 100,
          color: theme.hintColor,
        );
      case ErrorType.lottie:
        return SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/animations/error_full.json',
            fit: BoxFit.contain,
          ),
        );
      default:
        return Icon(
          Icons.error_outline,
          size: 100,
          color: theme.colorScheme.error,
        );
    }
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    Key? key,
    required this.onRetry,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      message: customMessage ?? 'Erreur de connexion',
      details: 'Vérifiez votre connexion internet et réessayez.',
      onRetry: onRetry,
      type: ErrorType.network,
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    this.icon,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 80,
            color: theme.hintColor,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Permission error widget
class PermissionErrorWidget extends StatelessWidget {
  final String permission;
  final VoidCallback onRequestPermission;

  const PermissionErrorWidget({
    Key? key,
    required this.permission,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getPermissionName() {
      switch (permission.toLowerCase()) {
        case 'camera':
          return 'Caméra';
        case 'photos':
        case 'gallery':
          return 'Galerie photos';
        case 'location':
          return 'Localisation';
        case 'microphone':
          return 'Microphone';
        case 'storage':
          return 'Stockage';
        default:
          return permission;
      }
    }

    return CustomErrorWidget(
      message: 'Permission requise',
      details: 'L\'application a besoin de la permission ${getPermissionName()} '
          'pour fonctionner correctement.',
      onRetry: onRequestPermission,
      type: ErrorType.permission,
    );
  }
}

/// Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        details: details,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (details != null) ...[
            const SizedBox(height: 12),
            Text(
              details!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('Ignorer'),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry?.call();
            },
            child: const Text('Réessayer'),
          ),
        if (onDismiss == null && onRetry == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
      ],
    );
  }
}

/// Snackbar error
class ErrorSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
          textColor: Colors.white,
        )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    show(
      context: context,
      message: 'Erreur de connexion. Vérifiez votre internet.',
      actionLabel: onRetry != null ? 'Réessayer' : null,
      onAction: onRetry,
    );
  }
}

/// Error banner
class ErrorBanner extends StatelessWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onClose;
  final ErrorBannerType type;

  const ErrorBanner({
    Key? key,
    required this.message,
    required this.isVisible,
    this.onClose,
    this.type = ErrorBannerType.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ErrorBannerType.error:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        icon = Icons.error_outline;
        break;
      case ErrorBannerType.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning_amber;
        break;
      case ErrorBannerType.info:
        backgroundColor = theme.primaryColor;
        textColor = theme.colorScheme.onPrimary;
        icon = Icons.info_outline;
        break;
      case ErrorBannerType.success:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: textColor, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

enum ErrorBannerType {
  error,
  warning,
  info,
  success,
}