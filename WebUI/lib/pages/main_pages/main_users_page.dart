import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webui/Struct/User.dart';
import 'package:webui/controllers/UserController.dart';
import 'package:webui/utils/snack_bar.dart';
import 'package:webui/widget/AsyncButton.dart';
import 'package:webui/widget/AsyncInput.dart';

import '../../widget/CopyableText.dart';
import '../../widget/SmoothScrollView.dart';

class MainUsersPage extends StatefulWidget {
  const MainUsersPage({super.key});

  static ValueNotifier<List<User>> users = ValueNotifier<List<User>>([]);
  static int page = 1;
  static int pageSize = 20;

  static Future<bool> getUsers(BuildContext context) async {
    final result = await UserController.listUsers(page, pageSize);
    if (result == null) {
      showErrorSnack(context, '获取用户列表失败!');
      return false;
    }

    users.value = result.data;
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
      padding: const EdgeInsets.only(left: 5, right: 5),
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
            return await MainUsersPage.getUsers(context);
          }),
          SizedBox(
            width: 50,
            child: TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 4, horizontal: 2),
                border: OutlineInputBorder(),),
            ),
          ),
          AsyncButton(type: .icon, child: Icon(Icons.navigate_next))
              .action(() async {
            return await MainUsersPage.getUsers(context);
          }),
          SizedBox(height: 15, child: VerticalDivider()),
          SizedBox(
            width: 50,
            child: TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 4, horizontal: 2),
                border: OutlineInputBorder(),),
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

class _UserTableState extends State<_UserTable> {
  final int _rowsPerPage = MainUsersPage.pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainUsersPage.getUsers(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery
        .of(context)
        .size
        .height * 0.8;

    return SizedBox(
      height: maxHeight,
      child: Container(
        decoration: BoxDecoration(color: Theme
            .of(context)
            .colorScheme
            .surfaceContainer, borderRadius: BorderRadius.circular(5)),
        clipBehavior: Clip.antiAlias,
        child: ValueListenableBuilder<List<User>>(
          valueListenable: MainUsersPage.users,
          builder: (context, list, _) {
            if (list.isEmpty) return const Center(child: Text('暂无数据'));
            return PaginatedDataTable2(
              hidePaginator: true,
              rowsPerPage: list.length.clamp(1, _rowsPerPage),
              columns: [
                DataColumn2(label: Text('ID'), size: ColumnSize.S),
                DataColumn2(label: Text('用户名'), size: ColumnSize.M),
                DataColumn2(label: Text('邮箱'), size: ColumnSize.S),
                DataColumn2(label: Text('管理员'), size: ColumnSize.S),
                DataColumn2(label: Text('封禁'), size: ColumnSize.S),
                DataColumn2(label: Text('创建时间'), size: ColumnSize.L),
                DataColumn2(label: Text('操作'), size: ColumnSize.L),
              ],
              source: _UserDataSource(list, context),
            );
          },
        ),
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  final List<User> users;
  final BuildContext context;

  _UserDataSource(this.users, this.context);

  @override
  DataRow getRow(int index) {
    final user = users[index];

    final rowColor = WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states) {
      if (index % 2 == 0) return Colors.grey.withOpacity(0.1);
      return null;
    });

    return DataRow(
      color: rowColor,
      cells: [
        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CopyableText(user.id.toString()))),
        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CopyableText(user.username))),
        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CopyableText(user.email))),
        DataCell(Icon(user.isAdmin ? Icons.check_circle : Icons.cancel,
            color: user.isAdmin ? Colors.green : Colors.grey, size: 20)),
        DataCell(Icon(user.isBanned ? Icons.check_circle : Icons.cancel,
            color: user.isBanned ? Colors.red : Colors.grey, size: 20)),
        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CopyableText(
                DateTime
                    .fromMillisecondsSinceEpoch(user.createTime)
                    .toString()))),
        DataCell(SizedBox(width: 150, child: _UserDataRowTool())),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}

class _UserDataRowTool extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserDataRowToolState();
}

class _UserDataRowToolState extends State<_UserDataRowTool> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AsyncButton(type: .icon, child: Icon(Icons.delete_forever_rounded)),
        AsyncButton(type: .icon, child: Icon(Icons.edit)),
      ],
    );
  }
}
