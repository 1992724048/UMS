import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:webui/Struct/User.dart';
import 'package:webui/controllers/UserController.dart';
import 'package:webui/utils/snack_bar.dart';
import 'package:webui/widget/AsyncButton.dart';
import 'package:webui/widget/SmoothScrollView.dart';

import '../../utils/Timestamp.dart';
import '../../utils/http.dart';
import '../../widget/ConfirmDialog.dart';
import '../../widget/CopyableText.dart';

class MainUsersPage extends StatefulWidget {
  const MainUsersPage({super.key});

  static ValueNotifier<List<User>> users = ValueNotifier<List<User>>([]);
  static ValueNotifier<int> totalPage = ValueNotifier(999);
  static ValueNotifier<int> totalSize = ValueNotifier(0);
  static TextEditingController pageInput = TextEditingController(text: '1');
  static TextEditingController pageSizeInput = TextEditingController(
      text: '20');

  static Future<bool> getUsers(BuildContext context) async {
    final result = await UserController.listUsers(
        int.parse(pageInput.text), int.parse(pageSizeInput.text));
    if (result == null) {
      showErrorSnack(context, '获取用户列表失败!');
      return false;
    }

    pageInput.text =
        math.min<int>(totalPage.value, int.parse(pageInput.text)).toString();
    users.value = result.data;
    totalSize.value = result.total;
    totalPage.value = result.totalPage;
    return true;
  }

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
    return Column(
      children: [
        _ToolBar(),
        SizedBox(height: 5),
        Expanded(child: _UserTable()),
      ],
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
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Theme
          .of(context)
          .colorScheme
          .surfaceContainer, borderRadius: .circular(5)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          AsyncButton(type: .filled, child: Text('刷新')).action(() async {
            return await MainUsersPage.getUsers(context);
          }),
          SizedBox(height: 15, child: VerticalDivider()),
          AsyncButton(type: .icon, child: Icon(Icons.navigate_before))
              .action(() async {
            int page = int.parse(MainUsersPage.pageInput.text);
            if (page <= 1) {
              return false;
            }
            MainUsersPage.pageInput.text = (page - 1).toString();
            return await MainUsersPage.getUsers(context);
          }),
          SizedBox(width: 5),
          SizedBox(
            width: 50,
            child: TextField(
              controller: MainUsersPage.pageInput,
              keyboardType: .number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
              onSubmitted: (value) => MainUsersPage.getUsers(context),
              decoration: InputDecoration(isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 4, horizontal: 2),
                  border: OutlineInputBorder()),
            ),
          ),
          ValueListenableBuilder(valueListenable: MainUsersPage.totalPage,
              builder: (context, value, child) => Text(' / ${value}')),
          SizedBox(width: 5),
          AsyncButton(type: .icon, child: Icon(Icons.navigate_next))
              .action(() async {
            int page = int.parse(MainUsersPage.pageInput.text);
            if (page >= MainUsersPage.totalPage.value) {
              return false;
            }
            MainUsersPage.pageInput.text = (page + 1).toString();
            return await MainUsersPage.getUsers(context);
          }),
          SizedBox(height: 15, child: VerticalDivider()),
          SizedBox(
            width: 50,
            child: TextField(
              controller: MainUsersPage.pageSizeInput,
              keyboardType: .number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
              onSubmitted: (value) => MainUsersPage.getUsers(context),
              decoration: InputDecoration(isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 4, horizontal: 2),
                  border: OutlineInputBorder()),
            ),
          ),
          SizedBox(height: 15, child: VerticalDivider()),
          IconButton(onPressed: () {}, icon: Icon(Icons.add_circle)),
          SizedBox(height: 15, child: VerticalDivider()),
        ],
      ),
    );
  }
}

class _UserTable extends StatefulWidget {
  const _UserTable();

  @override
  State<_UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<_UserTable>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainUsersPage.getUsers(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<User>>(
        valueListenable: MainUsersPage.users,
        builder: (context, list, _) {
          if (list.isEmpty) return const Center(child: Text('暂无数据'));
          return LayoutBuilder(
            builder: (context, constraints) {
              const double minCardWidth = 500;
              const double spacing = 5;

              final int crossAxisCount = math.max(
                  1, (constraints.maxWidth / (minCardWidth + spacing)).ceil());

              return MasonryGridView.count(
                physics: const ScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return SizedBox(width: 500,
                      height: 200,
                      child: _UserDataCard(user: list[index]));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UserDataCard extends StatelessWidget {
  User user;

  _UserDataCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme
          .of(context)
          .colorScheme
          .surfaceContainer,
      decoration: BoxDecoration(color: Theme
          .of(context)
          .colorScheme
          .surfaceContainer, borderRadius: BorderRadius.circular(5)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: .start,
                children: [
                  Row(
                    crossAxisAlignment: .center,
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 5),
                      Text(user.username, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Divider(endIndent: 5),
                  Row(
                    children: [
                      if (user.isAdmin) ...{
                        Container(
                          decoration: BoxDecoration(color: Colors.green,
                              borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.all(3),
                          child: const Text('管理员', style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                        ),
                      } else
                        ...{
                          Container(
                            decoration: BoxDecoration(color: Colors.blue,
                                borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.all(3),
                            child: const Text('用户', style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                          ),
                        },
                      if (user.isBanned) ...{
                        SizedBox(width: 5),
                        Container(
                          decoration: BoxDecoration(color: Colors.red,
                              borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.all(3),
                          child: const Text('被封禁', style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                        ),
                      },
                    ],
                  ),
                  Divider(endIndent: 5),
                  Row(children: [Text('ID:'), Text('${user.id}')]),
                  Row(children: [
                    Text('注册时间:'),
                    Text(formatTimestamp(user.createTime))
                  ]),
                  Row(children: [Text('邮箱地址：'), Text(user.email)]),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 0),
          SizedBox(
            width: 50,
            child: Padding(
              padding: EdgeInsetsGeometry.only(top: 3, bottom: 3),
              child: Column(
                spacing: 3,
                crossAxisAlignment: .center,
                mainAxisAlignment: .start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: () async {
                      await UserEditDialog.show(context, user);
                      await MainUsersPage.getUsers(context);
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: '编辑',
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onPressed: () async {
                      final confirm = await ConfirmDialog.show(
                          context, title: '确认删除',
                          content: '确定要删除用户 "${user.username}" 吗？',
                          confirmText: '删除');
                      if (!confirm) return;
                      if (await UserController.delete(user.id)) {
                        await MainUsersPage.getUsers(context);
                        return;
                      }
                      showErrorSnack(context, '删除失败');
                    },
                    icon: const Icon(Icons.delete),
                    tooltip: '删除',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserEditDialog extends StatefulWidget {
  final User user;

  const UserEditDialog({super.key, required this.user});

  static Future<bool?> show(BuildContext context, User user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PopScope(canPop: false, child: UserEditDialog(user: user)),
    );
  }

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;

  late bool _isAdmin;
  late bool _isBanned;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController();
    _emailController = TextEditingController(text: widget.user.email);

    _isAdmin = widget.user.isAdmin;
    _isBanned = widget.user.isBanned;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑用户'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '新密码（留空不修改）'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '邮箱'),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('管理员'),
                value: _isAdmin,
                onChanged: (value) {
                  setState(() {
                    _isAdmin = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('封禁用户'),
                value: _isBanned,
                onChanged: (value) {
                  setState(() {
                    _isBanned = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消')),
        FilledButton(
          onPressed: () async {
            final user = User(
              id: widget.user.id,
              username: _usernameController.text,
              password: _passwordController.text,
              email: _emailController.text,
              isAdmin: _isAdmin,
              isBanned: _isBanned,
              createTime: widget.user.createTime,
            );
            final result = await UserController.update(user);
            if (result.$1 == 200) {
              Navigator.of(context).pop();
              return;
            }
            showErrorSnack(context, result.$2);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
