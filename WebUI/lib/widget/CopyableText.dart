import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration longPressDuration;

  const CopyableText(
    this.text, {
    super.key,
    this.style,
    this.longPressDuration = const Duration(milliseconds: 500),
  });

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  bool _isLongPressing = false;
  Offset? _longPressPosition;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.longPressDuration,
    );
    _controller.addListener(() {
      setState(() {
        _progress = _controller.value;
      });
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isLongPressing = true;
      _longPressPosition = details.globalPosition;
    });
    _controller.forward().then((_) {
      if (_controller.isCompleted) {
        _onLongPressComplete();
      }
    });
  }

  void _onLongPressComplete() {
    Clipboard.setData(ClipboardData(text: widget.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: ${widget.text}'),
        duration: const Duration(seconds: 1),
      ),
    );
    _reset();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _reset();
  }

  void _reset() {
    _controller.stop();
    _controller.reset();
    setState(() {
      _isLongPressing = false;
      _longPressPosition = null;
      _progress = 0.0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Tooltip(
              message: '长按复制',
              child: Text(
                widget.text,
                style: widget.style?.copyWith(
                  decoration: _isHovering ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (_isLongPressing && _longPressPosition != null)
              _buildProgressIndicatorAtPosition(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicatorAtPosition(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final localPosition = renderBox.globalToLocal(_longPressPosition!);

    return Positioned(
      left: localPosition.dx - 20,
      top: localPosition.dy - 20,
      child: IgnorePointer(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
