import 'package:flutter/material.dart';
import 'package:md_icons/md_icons.dart';
import 'package:webui/widget/CustomCard.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      mainAxisAlignment: .start,
      children: [
        Column(
          children: [
            CustomCard(
              icon: MDIcons.bulletinBoard,
              title: Text('公告', style: TextStyle(fontSize: 17)),
              titleSpacing: 5,
              child: Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: .start,
                children: [Text('v1.0.0 (Dev): 开发版本')],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
