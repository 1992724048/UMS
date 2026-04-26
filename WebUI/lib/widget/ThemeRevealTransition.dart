import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ThemeRevealController {
  void Function(Offset)? _trigger;

  void toggle({Offset center = Offset.zero}) => _trigger?.call(center);
}

class ThemeRevealTransition extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback onToggle;
  final Color seedColor;
  final ValueChanged<Color>? onColorChanged;
  final ThemeRevealController? controller;
  final bool showButton;
  final Duration duration;

  const ThemeRevealTransition({
    super.key,
    required this.child,
    required this.isDark,
    required this.onToggle,
    this.seedColor = const Color(0xFF448AFF),
    this.onColorChanged,
    this.duration = const Duration(milliseconds: 500),
    this.controller,
    this.showButton = true,
  });

  @override
  State<ThemeRevealTransition> createState() => _ThemeRevealTransitionState();
}

class _ThemeRevealTransitionState extends State<ThemeRevealTransition> with SingleTickerProviderStateMixin {
  static const _presetColors = [
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
    Color(0xFF42A5F5),
    Color(0xFF90CAF9),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFF795548),
  ];
  late AnimationController _controller;
  late CurvedAnimation _animation;
  bool _showReveal = false;
  Offset _revealCenter = Offset.zero;
  final _screenshotKey = GlobalKey();
  ui.Image? _capturedImage;
  bool _showPalette = false;
  double _maxRadius = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    widget.controller?._trigger = _handleTap;
  }

  @override
  void dispose() {
    widget.controller?._trigger = null;
    _capturedImage?.dispose();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(Offset globalPosition) async {
    if (_showReveal) return;
    _revealCenter = globalPosition;
    if (_showPalette) setState(() => _showPalette = false);

    final renderObject = _screenshotKey.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      final dpr = View.of(context).devicePixelRatio;
      _capturedImage = await renderObject.toImage(pixelRatio: dpr);
    }

    if (!mounted) return;

    widget.onToggle();

    var size = MediaQuery.sizeOf(context);
    final corners = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)];
    _maxRadius = corners.map((c) => (c - _revealCenter).distance).reduce(math.max);

    setState(() => _showReveal = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward().whenComplete(() {
          _capturedImage?.dispose();
          _capturedImage = null;
          if (mounted) {
            setState(() => _showReveal = false);
          }
          _controller.reset();
        });
      }
    });
  }

  Widget _buildColorGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _presetColors.map((color) {
        final isSelected = color.value == widget.seedColor.value;
        return GestureDetector(
          onTap: () {
            widget.onColorChanged?.call(color);
            setState(() => _showPalette = false);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2.5) : null,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 18, color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPalette() {
    return GestureDetector(
      onTap: () => setState(() => _showPalette = !_showPalette),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.seedColor,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(
          Icons.palette,
          size: 16,
          color: widget.seedColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildToggle(ThemeData theme) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details.globalPosition),
      child: Container(
        width: 58,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: widget.isDark ? Alignment.centerRight : Alignment.centerLeft,
              duration: widget.duration,
              curve: Curves.fastOutSlowIn,
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Icon(
                        Icons.light_mode,
                        size: 15,
                        color: widget.isDark
                            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        Icons.dark_mode,
                        size: 15,
                        color: widget.isDark
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _screenshotKey, child: widget.child),
        if (_showReveal && _capturedImage != null)
          IgnorePointer(
            child: _RevealClip(
              animation: _animation,
              center: _revealCenter,
              maxRadius: _maxRadius,
              child: SizedBox.expand(child: CustomPaint(painter: _ImagePainter(_capturedImage!))),
            ),
          ),
        if (widget.showButton)
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 160,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      alignment: Alignment.bottomCenter,
                      heightFactor: _showPalette ? 1.0 : 0.0,
                      child: Padding(padding: const EdgeInsets.all(8), child: _buildColorGrid(theme)),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onColorChanged != null) _buildPalette(),
                    if (widget.onColorChanged != null) const SizedBox(width: 8),
                    _buildToggle(theme),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InverseCircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double progress;
  final double maxRadius;

  _InverseCircleClipper({required this.center, required this.progress, required this.maxRadius});

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
    ..addOval(Rect.fromCircle(center: center, radius: progress * maxRadius))
    ..fillType = PathFillType.evenOdd;

  @override
  bool shouldReclip(_InverseCircleClipper old) => old.progress != progress;
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & Size(size.width + 0, size.height),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_ImagePainter old) => old.image != image;
}

class _RevealClip extends AnimatedWidget {
  final Widget child;
  final Offset center;
  final double maxRadius;

  const _RevealClip({
    required Animation<double> animation,
    required this.child,
    required this.center,
    required this.maxRadius,
  }) : super(listenable: animation);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _InverseCircleClipper(center: center, progress: _progress.value, maxRadius: maxRadius),
      child: child,
    );
  }
}
