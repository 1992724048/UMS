import 'package:flutter/material.dart';

import 'AsyncWidget.dart';

enum AsyncButtonType { elevated, outlined, text }

class AsyncButton extends AsyncActionWidget<AsyncButton> {
  final Widget child;
  final AsyncButtonType type;
  final ButtonStyle? style;
  final double loadingIndicatorSize;

  const AsyncButton({
    super.key,
    super.action_,
    super.errorHandler,
    super.timeout,
    super.progressNotifier,
    super.readOnlyNotifier,
    required this.child,
    this.type = AsyncButtonType.elevated,
    this.style,
    this.loadingIndicatorSize = 18,
  });

  @override
  AsyncButton copyWith({
    Future<bool> Function()? action_,
    ErrorCallback? errorHandler,
    Duration? timeout,
    ValueNotifier<double>? progressNotifier,
    ValueNotifier<bool>? readOnlyNotifier,
  }) {
    return AsyncButton(
      key: key,
      action_: action_ ?? this.action_,
      errorHandler: errorHandler ?? this.errorHandler,
      timeout: timeout ?? this.timeout,
      progressNotifier: progressNotifier ?? this.progressNotifier,
      readOnlyNotifier: readOnlyNotifier ?? this.readOnlyNotifier,
      type: type,
      style: style,
      loadingIndicatorSize: loadingIndicatorSize,
      child: child,
    );
  }

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends AsyncActionWidgetState<AsyncButton> {
  OutlinedBorder _resolveShape(BuildContext context) {
    final theme = Theme.of(context);
    OutlinedBorder? s;

    switch (widget.type) {
      case AsyncButtonType.elevated:
        s = widget.style?.shape?.resolve({});
        s ??= theme.elevatedButtonTheme.style?.shape?.resolve({});
        return s ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
      case AsyncButtonType.text:
        s = widget.style?.shape?.resolve({});
        s ??= theme.textButtonTheme.style?.shape?.resolve({});
        return s ?? RoundedRectangleBorder();
      case AsyncButtonType.outlined:
        s = widget.style?.shape?.resolve({});
        s ??= theme.outlinedButtonTheme.style?.shape?.resolve({});
        return s ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    }
  }

  @override
  Widget buildContent(BuildContext context, bool busy, double? progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasProgress = progress != null && progress != -1;
    final shape = _resolveShape(context);

    Widget buildButton(Widget child) {
      switch (widget.type) {
        case AsyncButtonType.elevated:
          return ElevatedButton(onPressed: busy ? null : execute, style: widget.style, child: child);
        case AsyncButtonType.text:
          return TextButton(onPressed: busy ? null : execute, style: widget.style, child: child);
        case AsyncButtonType.outlined:
          return OutlinedButton(onPressed: busy ? null : execute, style: widget.style, child: child);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (busy)
              Positioned.fill(
                child: ClipPath.shape(
                  shape: shape,
                  child: hasProgress
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress.clamp(0, 1),
                            child: Container(color: colorScheme.primary.withAlpha(127)),
                          ),
                        )
                      : LinearProgressIndicator(backgroundColor: Colors.transparent),
                ),
              ),
            buildButton(
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: busy ? 0.5 : 1.0,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
