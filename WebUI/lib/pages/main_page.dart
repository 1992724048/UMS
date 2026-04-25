import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:md_icons/md_icons.dart';
import '../mixin/page_load_timer.dart';
import '../utils/http.dart';
import 'main_home_page.dart';

class MainPageRoutes {
  static const String home = 'home';
  static const String apps = 'apps';
  static const String users = 'users';
  static const String keys = 'keys';
  static const String datas = 'datas';
  static const String files = 'files';
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
      pageWidget: Column(
        children: [Text('3', style: TextStyle(color: Colors.white))],
      ),
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
      final req = await HttpClient.get('/api/System/admin_check');
      if (!mounted) return;
      if (req.status != 200) {
        context.go('/');
      }
    } catch (_) {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: _AppTopBar(),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: _BodyPage(),
      ),
      floatingActionButton: Text(
        '1.0.0 (Dev)\n${MainPage.duration.inMilliseconds} ms',
        style: TextStyle(color: Colors.white24),
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

class _AppTopBar extends StatefulWidget {
  const _AppTopBar();

  @override
  State<StatefulWidget> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<_AppTopBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: .center,
            children: [Text('管理系统后台面板', style: TextStyle(fontSize: 18))],
          ),
        ),
        IconButton(
          onPressed: () async {
            try {
              final req = await HttpClient.post('/api/User/logout');
              if (!mounted) return;
              if (req.status == 200) {
                context.go('/');
              }
            } catch (_) {}
          },
          tooltip: '登出',
          icon: Icon(Icons.logout),
        ),
      ],
    );
  }
}

class _BodyPage extends StatefulWidget {
  const _BodyPage();

  @override
  State<StatefulWidget> createState() => _BodyPageState();
}

class _BodyPageState extends State<_BodyPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = MainPageRoutes.home;

  void _navigateTo(String routeName) {
    if (_currentRoute == routeName) return;
    _navigatorKey.currentState?.pushReplacementNamed(routeName, result: null);
    setState(() {
      _currentRoute = routeName;
    });
  }

  Widget _buildPageForRoute(String routeName) {
    final allItems = [...MainPage.navTopItems, ...MainPage.navBottomItems];
    final item = allItems.firstWhere((item) => item.route == routeName, orElse: () => MainPage.navTopItems.first);
    return item.pageWidget;
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => _buildPageForRoute(settings.name ?? MainPageRoutes.home),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          _SideBar(currentRoute: _currentRoute, onRouteSelected: _navigateTo),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: EdgeInsetsGeometry.all(5),
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: MainPageRoutes.home,
                    onGenerateRoute: _onGenerateRoute,
                  ),
                ),
              ),
            ),
          ),
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
          padding: EdgeInsetsGeometry.only(top: 5, bottom: 5),
          child: Column(
            children: [
              Expanded(child: Column(spacing: 5, children: [..._buildFromItems(MainPage.navTopItems)])),
              ..._buildFromItems(MainPage.navBottomItems),
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
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
      ),
    );
  }
}
