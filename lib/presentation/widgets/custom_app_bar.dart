import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/profile/presentation/widgets/profile_avatar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showProfileButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.showProfileButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.leading,
    this.bottom,
    this.titleSpacing,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? theme.appBarTheme.titleTextStyle?.color,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: _buildLeading(context),
      actions: _buildActions(context),
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      titleSpacing: titleSpacing,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(0),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: foregroundColor ?? Theme.of(context).appBarTheme.iconTheme?.color,
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      );
    }

    // Show logo or nothing
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        'assets/images/logo.png',
        height: 40,
        width: 40,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Add profile button if enabled
    if (showProfileButton) {
      actionWidgets.add(
        StreamBuilder<UserModel?>(
          stream: context.read<AuthService>().authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProfileAvatar(
                  photoUrl: user?.photoUrl,
                  name: user?.name,
                  email: user?.email,
                  size: 40,
                ),
              ),
            );
          },
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Add menu button if no actions
    if (actionWidgets.isEmpty) {
      actionWidgets.add(
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: foregroundColor ?? Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: () {
            _showMenu(context);
          },
        ),
      );
    }

    return actionWidgets;
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                      (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Aide'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
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
              final authService = context.read<AuthService>();
              await authService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                    (route) => false,
              );
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
}

/// Search App Bar
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onCancel;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const SearchAppBar({
    Key? key,
    required this.hintText,
    required this.onSearch,
    this.onCancel,
    this.actions,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _SearchAppBarState createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: widget.automaticallyImplyLeading
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_isSearching) {
            _cancelSearch();
          } else {
            Navigator.pop(context);
          }
        },
      )
          : null,
      title: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor.withOpacity(0.6),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          widget.onSearch(value);
          setState(() => _isSearching = value.isNotEmpty);
        },
        onSubmitted: (value) => widget.onSearch(value),
      ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
        ...?widget.actions,
      ],
    );
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    setState(() => _isSearching = false);
  }

  void _cancelSearch() {
    _clearSearch();
    widget.onCancel?.call();
  }
}

/// Transparent App Bar
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? titleColor;

  const TransparentAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.titleColor,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: titleColor ?? Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }
}

/// Gradient App Bar
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Gradient? gradient;
  final bool showBackButton;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.gradient,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: gradient ??
              LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        ),
      ),
      elevation: 0,
    );
  }
}

/// Sliver App Bar with background image
class SliverImageAppBar extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double expandedHeight;
  final List<Widget>? actions;

  const SliverImageAppBar({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.expandedHeight = 200,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      snap: false,
      stretch: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 60,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}