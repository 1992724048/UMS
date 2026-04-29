import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webui/widget/AsyncButton.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: .min,
          children: [
            Row(
              mainAxisAlignment: .center,
              mainAxisSize: .min,
              children: [
                Text(
                  '前面的区域以后再来探索吧!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AsyncButton(
              child: Row(
                mainAxisSize: .min,
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                children: [const Icon(Icons.home), const Text(' 返回首页')],
              ),
            ).action(() async {
              context.go('/');
              return true;
            }),
          ],
        ),
      ),
    );
  }
}
