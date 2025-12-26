import 'package:flutter/material.dart';

class SnackbarHelper {
  // Show success snackbar
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show error snackbar
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show warning snackbar
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show info snackbar
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show loading snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading({
    required BuildContext context,
    required String message,
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(days: 1), // Will be dismissed manually
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show action snackbar with retry button
  static void showAction({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
          textColor: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show snackbar with custom color
  static void showCustom({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    Color textColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Dismiss all snackbars
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  // Show snackbar with undo action
  static void showUndo({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 5),
  }) {
    showAction(
      context: context,
      message: message,
      actionLabel: 'Annuler',
      onAction: onUndo,
      duration: duration,
    );
  }

  // Show network error snackbar with retry
  static void showNetworkError({
    required BuildContext context,
    required VoidCallback onRetry,
    String message = 'Erreur réseau. Vérifiez votre connexion.',
  }) {
    showError(
      context: context,
      message: message,
      action: SnackBarAction(
        label: 'Réessayer',
        onPressed: onRetry,
        textColor: Colors.white,
      ),
    );
  }

  // Show authentication error snackbar
  static void showAuthError({
    required BuildContext context,
    String message = 'Erreur d\'authentification. Veuillez vous reconnecter.',
  }) {
    showError(
      context: context,
      message: message,
      action: SnackBarAction(
        label: 'Se connecter',
        onPressed: () {
          // Navigate to login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
                (route) => false,
          );
        },
        textColor: Colors.white,
      ),
    );
  }

  // Show device offline snackbar
  static void showDeviceOffline({
    required BuildContext context,
    String deviceName = 'l\'appareil',
    Duration duration = const Duration(seconds: 3),
  }) {
    showWarning(
      context: context,
      message: '$deviceName est hors ligne',
      duration: duration,
    );
  }

  // Show data saved successfully
  static void showDataSaved({
    required BuildContext context,
    String message = 'Données enregistrées avec succès',
  }) {
    showSuccess(
      context: context,
      message: message,
    );
  }

  // Show copy to clipboard confirmation
  static void showCopiedToClipboard({
    required BuildContext context,
    String message = 'Copié dans le presse-papier',
  }) {
    showInfo(
      context: context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper method to handle API errors
  static void showApiError({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
  }) {
    String message;

    if (error is String) {
      message = error;
    } else if (error is Map<String, dynamic>) {
      message = error['message'] ?? 'Une erreur est survenue';
    } else {
      message = error.toString();
    }

    if (message.contains('network') || message.contains('timeout')) {
      showNetworkError(context: context, onRetry: onRetry ?? () {});
    } else if (message.contains('auth') || message.contains('unauthorized')) {
      showAuthError(context: context);
    } else {
      showError(context: context, message: message);
    }
  }
}