import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/colors.dart';

/// Main loading widget with multiple styles
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final EdgeInsetsGeometry padding;
  final LoadingType type;
  final bool showBackground;
  final double strokeWidth;

  const LoadingWidget({
    Key? key,
    this.message,
    this.color,
    this.size,
    this.padding = const EdgeInsets.all(20),
    this.type = LoadingType.circular,
    this.showBackground = false,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;

    return Center(
      child: Container(
        padding: padding,
        decoration: showBackground
            ? BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoader(primaryColor, theme),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoader(Color color, ThemeData theme) {
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case LoadingType.linear:
        return SizedBox(
          width: size ?? 200,
          child: LinearProgressIndicator(
            minHeight: strokeWidth,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case LoadingType.dots:
        return SizedBox(
          width: size ?? 60,
          height: size ?? 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: color, delay: 0),
              _Dot(color: color, delay: 200),
              _Dot(color: color, delay: 400),
            ],
          ),
        );
      case LoadingType.pulse:
        return _PulseLoader(color: color, size: size ?? 40);
      case LoadingType.spinner:
        return SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
          ),
        );
      case LoadingType.lottie:
        return SizedBox(
          width: size ?? 100,
          height: size ?? 100,
          child: Lottie.asset(
            'assets/animations/loading.json',
            fit: BoxFit.contain,
          ),
        );
    }
  }
}

/// Loading types
enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  spinner,
  lottie,
}

/// Dot loading animation
class _Dot extends StatefulWidget {
  final Color color;
  final int delay;

  const _Dot({
    Key? key,
    required this.color,
    required this.delay,
  }) : super(key: key);

  @override
  _DotState createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Pulse loading animation
class _PulseLoader extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseLoader({
    Key? key,
    required this.color,
    required this.size,
  }) : super(key: key);

  @override
  _PulseLoaderState createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(1 - _animation.value * 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Full screen loading widget
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Widget? customLoader;
  final LoadingType type;

  const FullScreenLoading({
    Key? key,
    this.message,
    this.backgroundColor,
    this.customLoader,
    this.type = LoadingType.circular,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          customLoader ??
              LoadingWidget(
                type: type,
                size: 60,
                message: message,
                showBackground: true,
              ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _Shimmer(
          child: widget.child,
          gradient: LinearGradient(
            colors: [
              Colors.grey[300]!,
              Colors.grey[100]!,
              Colors.grey[300]!,
            ],
            stops: const [0.1, 0.3, 0.4],
            begin: const Alignment(-1.0, -0.3),
            end: const Alignment(1.0, 0.3),
            tileMode: TileMode.clamp,
            transform: _SlidingGradientTransform(_controller.value),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class _Shimmer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const _Shimmer({
    Key? key,
    required this.child,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: child,
    );
  }
}

/// Skeleton loading widgets
class SkeletonLoading extends StatelessWidget {
  final double width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoading({
    Key? key,
    required this.width,
    this.height,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 16,
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: ShimmerLoading(
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Card skeleton
class CardSkeleton extends StatelessWidget {
  final bool hasImage;
  final bool hasActions;

  const CardSkeleton({
    Key? key,
    this.hasImage = true,
    this.hasActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              SkeletonLoading(
                width: double.infinity,
                height: 150,
                borderRadius: BorderRadius.circular(8),
                margin: const EdgeInsets.only(bottom: 16),
              ),
            SkeletonLoading(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
            ),
            SkeletonLoading(
              width: double.infinity * 0.7,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            if (hasActions)
              Row(
                children: [
                  SkeletonLoading(
                    width: 80,
                    height: 36,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const Spacer(),
                  SkeletonLoading(
                    width: 80,
                    height: 36,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// List skeleton loading
class ListSkeletonLoading extends StatelessWidget {
  final int itemCount;
  final bool hasLeading;
  final bool hasSubtitle;
  final bool hasTrailing;

  const ListSkeletonLoading({
    Key? key,
    this.itemCount = 5,
    this.hasLeading = true,
    this.hasSubtitle = true,
    this.hasTrailing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasLeading)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SkeletonLoading(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    if (hasSubtitle)
                      SkeletonLoading(
                        width: double.infinity * 0.7,
                      ),
                  ],
                ),
              ),
              if (hasTrailing)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SkeletonLoading(
                    width: 24,
                    height: 24,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Grid skeleton loading
class GridSkeletonLoading extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final int itemCount;

  const GridSkeletonLoading({
    Key? key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.circular(8),
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                SkeletonLoading(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                SkeletonLoading(
                  width: double.infinity * 0.6,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                const Spacer(),
                SkeletonLoading(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? overlayColor;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: LoadingWidget(
                message: message,
                showBackground: true,
                type: LoadingType.circular,
                size: 50,
              ),
            ),
          ),
      ],
    );
  }
}