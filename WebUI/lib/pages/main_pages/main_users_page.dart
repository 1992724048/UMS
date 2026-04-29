import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:webui/widget/AsyncButton.dart';
import 'package:webui/widget/CustomCard.dart';

import '../../widget/SmoothScrollView.dart';

class MainUsersPage extends StatefulWidget {
  const MainUsersPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainUsersPageState();
}

class _MainUsersPageState extends State<MainUsersPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SmoothScrollView(
      scrollSpeed: 2,
      damping: 0.25,
      child: Column(children: [_ToolBar()]),
    );
  }
}

class _ToolBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ToolBarState();
}

class _ToolBarState extends State<_ToolBar> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [AsyncButton(child: Text('刷新'))]);
  }
}
