import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:webui/widget/CustomCard.dart';

import '../widget/SmoothScrollView.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minCardWidth = 700;
          const double spacing = 10;

          final int crossAxisCount = math.max(1, (constraints.maxWidth / (minCardWidth + spacing)).ceil());
          final double cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

          return MasonryGridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            itemCount: 5,
            itemBuilder: (context, index) {
              return switch (index) {
                0 => SizedBox(width: cardWidth, child: _NoticeCard()),
                _ => const SizedBox(),
              };
            },
          );
        },
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomCard(
    title: Text('更新公告', style: TextStyle(fontSize: 17)),
    titleSpacing: 5,
    child: Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .start,
      children: [Text('v1.0.0 (Dev): 开发版本🛠️<-测试emoji用的\n😡😊😨😭😂🤣❤️😍😒👌')],
    ),
  );
}
