import 'package:flutter/cupertino.dart';

mixin PageLoadTimer<T extends StatefulWidget> on State<T> {
  final Stopwatch _timer = Stopwatch();

  @override
  void initState() {
    super.initState();
    _timer.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer.stop();
      onPageLoaded(_timer.elapsed);
    });
  }

  void onPageLoaded(Duration duration);
}
