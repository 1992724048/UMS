import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:md_icons/md_icons.dart';
import 'package:webui/controllers/UserController.dart';
import '../mixin/page_load_timer.dart';
import 'main_pages/main_home_page.dart';
import 'main_pages/main_users_page.dart';

class MainPageRoutes {
  static const String home = 'home';
  static const String apps = 'apps';
  static const String users = 'users';
  static const String keys = 'keys';
  static const String datas = 'datas';
  static const String files = 'files';
  static const String webs = 'webs';
  static const String customerService = 'customer_service';
  static const String aiAgent = 'ai_agent';
  static const String audit = 'audit';
  static const String setting = 'setting';
}

class MainPageNavItem {
  final IconData icon;
  final String tooltip;
  final String route;
  final Widget pageWidget;
  final Widget? prevWidget;
  final Widget? nextWidget;

  const MainPageNavItem({
    required this.icon,
    required this.tooltip,
    required this.route,
    required this.pageWidget,
    this.prevWidget,
    this.nextWidget,
  });
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static Duration duration = Duration();
  static List<MainPageNavItem> navTopItems = [
    MainPageNavItem(
      icon: Icons.home,
      tooltip: '主页',
      route: MainPageRoutes.home,
      nextWidget: const Divider(indent: 15, endIndent: 15),
      pageWidget: MainHomePage(),
    ),
    const MainPageNavItem(
      icon: Icons.app_registration,
      tooltip: '应用',
      route: MainPageRoutes.apps,
      pageWidget: Column(
        children: [Text('2', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.supervised_user_circle,
      tooltip: '用户',
      route: MainPageRoutes.users,
      pageWidget: MainUsersPage(),
    ),
    const MainPageNavItem(
      icon: Icons.key,
      tooltip: '密钥',
      route: MainPageRoutes.keys,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.data_array,
      tooltip: '数据',
      route: MainPageRoutes.datas,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.file_present_rounded,
      tooltip: '文件',
      route: MainPageRoutes.files,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.web,
      tooltip: '网站',
      route: MainPageRoutes.webs,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.support_agent,
      tooltip: '客服',
      route: MainPageRoutes.customerService,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: Icons.assistant,
      tooltip: 'AI代理',
      route: MainPageRoutes.aiAgent,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
    const MainPageNavItem(
      icon: MDIcons.shieldCheck,
      tooltip: '审计',
      route: MainPageRoutes.audit,
      pageWidget: Column(
        children: [Text('4', style: TextStyle(color: Colors.white))],
      ),
    ),
  ];

  static List<MainPageNavItem> navBottomItems = const [
    MainPageNavItem(
      icon: Icons.settings,
      tooltip: '设置',
      route: MainPageRoutes.setting,
      prevWidget: Divider(indent: 15, endIndent: 15),
      pageWidget: Column(
        children: [Text('5', style: TextStyle(color: Colors.white))],
      ),
    ),
  ];

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with PageLoadTimer {
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final req = await UserController.adminCheck();
      if (!mounted) return;
      if (!req) {
        context.go('/');
      }
    } catch (_) {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _BodyPage(),
      floatingActionButton: Padding(
        padding: EdgeInsetsGeometry.only(bottom: 35),
        child: Text(
          '1.0.0 (Dev)\n${MainPage.duration.inMilliseconds} ms',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleSmall?.color?.withAlpha(50),
          ),
        ),
      ),
    );
  }

  @override
  void onPageLoaded(Duration duration) {
    setState(() {
      MainPage.duration = duration;
    });
  }
}

class _BodyPage extends StatefulWidget {
  const _BodyPage();

  @override
  State<StatefulWidget> createState() => _BodyPageState();
}

class _BodyPageState extends State<_BodyPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [...MainPage.navTopItems, ...MainPage.navBottomItems];
    final currentRoute = allItems[_currentIndex].route;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          _SideBar(
            currentRoute: currentRoute,
            onRouteSelected: (route) {
              final newIndex = allItems.indexWhere(
                (item) => item.route == route,
              );
              if (newIndex != -1) {
                setState(() {
                  _currentIndex = newIndex;
                  _pageController.animateToPage(
                    _currentIndex,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              }
            },
          ),
          _PageBody(pageController: _pageController, allItems: allItems),
        ],
      ),
    );
  }
}

class _SideBar extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteSelected;

  const _SideBar({required this.currentRoute, required this.onRouteSelected});

  @override
  State<StatefulWidget> createState() => _SideBarState();
}

class _SideBarState extends State<_SideBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SizedBox(
        width: 50,
        child: Padding(
          padding: .only(top: 5, bottom: 5),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  spacing: 5,
                  children: [..._buildFromItems(MainPage.navTopItems)],
                ),
              ),
              ..._buildFromItems(MainPage.navBottomItems),
              IconButton(
                onPressed: () async {
                  if (!mounted) return;
                  if (await UserController.logout()) {
                    if (!mounted) return;
                    context.go('/');
                  }
                },
                tooltip: '登出',
                icon: Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFromItems(List<MainPageNavItem> items) {
    return [
      for (final item in items) ...{
        if (item.prevWidget != null) item.prevWidget!,
        _buildNavButton(item),
        if (item.nextWidget != null) item.nextWidget!,
      },
    ];
  }

  Widget _buildNavButton(MainPageNavItem item) {
    final isSelected = widget.currentRoute == item.route;

    return IconButton(
      onPressed: () => widget.onRouteSelected(item.route),
      tooltip: item.tooltip,
      icon: Icon(item.icon),
      color: isSelected ? Theme.of(context).colorScheme.primary : null,
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
      ),
    );
  }
}

class _PageBody extends StatefulWidget {
  final PageController pageController;
  final List<MainPageNavItem> allItems;

  const _PageBody({required this.pageController, required this.allItems});

  @override
  State<StatefulWidget> createState() => _PageBodyState();
}

class _PageBodyState extends State<_PageBody> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: .circular(10)),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const .all(5),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: PageView(
                controller: widget.pageController,
                scrollDirection: .vertical,
                physics: const NeverScrollableScrollPhysics(),
                children: widget.allItems.asMap().entries.map((entry) {
                  final item = entry.value;
                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: item.pageWidget,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
