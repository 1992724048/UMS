import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class SmoothScrollView extends StatefulWidget {
  final Widget child;
  final double scrollSpeed;
  final double damping;
  final int minDuration;
  final int maxDuration;
  final Curve curve;

  final ScrollController? controller;

  const SmoothScrollView({
    super.key,
    required this.child,
    this.controller,
    this.scrollSpeed = 1.0,
    this.damping = 0.15,
    this.minDuration = 80,
    this.maxDuration = 220,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SmoothScrollView> createState() => _SmoothScrollViewState();
}

class _SmoothScrollViewState extends State<SmoothScrollView>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  late final AnimationController _anim;
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _anim = AnimationController(vsync: this)..addListener(_tick);
  }

  void _tick() {
    final current = _controller.offset;
    final delta = (_target - current) * widget.damping;

    if (delta.abs() < 0.3) {
      _controller.jumpTo(_target);
      _anim.stop();
    } else {
      _controller.jumpTo(current + delta);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _target += event.scrollDelta.dy * widget.scrollSpeed;
      _target = _target.clamp(0.0, _controller.position.maxScrollExtent);

      final velocity = event.scrollDelta.dy.abs();
      final duration = (widget.maxDuration -
          (velocity * 0.5).clamp(0, widget.maxDuration)).toInt().clamp(
          widget.minDuration, widget.maxDuration);

      _anim
        ..duration = Duration(milliseconds: duration)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: SingleChildScrollView(
          controller: _controller, child: widget.child),
    );
  }
}
