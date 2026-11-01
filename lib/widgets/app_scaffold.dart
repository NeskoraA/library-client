import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';
import '../state/permissions.dart';

class Section {
  final String path;
  final String label;
  final IconData icon;
  final Permission permission;

  const Section(this.path, this.label, this.icon, this.permission);
}

const sections = [
  Section('/books', 'Книги', Icons.menu_book, Permission.viewCatalog),
  Section('/authors', 'Авторы', Icons.person, Permission.viewCatalog),
  Section('/genres', 'Жанры', Icons.category, Permission.viewCatalog),
  Section(
    '/publishers',
    'Издательства',
    Icons.business,
    Permission.viewCatalog,
  ),
  Section('/my-loans', 'Мои выдачи', Icons.bookmark, Permission.viewOwnLoans),
  Section('/readers', 'Читатели', Icons.badge, Permission.manageReaders),
  Section('/loans', 'Выдачи', Icons.swap_horiz, Permission.manageLoans),
  Section(
    '/admin/users',
    'Пользователи',
    Icons.manage_accounts,
    Permission.manageUsers,
  ),
  Section('/admin/stats', 'Статистика', Icons.bar_chart, Permission.viewStats),
];

const compactWidth = 600.0;
const expandedWidth = 1200.0;
const contentMaxWidth = 1400.0;

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const AppScaffold({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final location = GoRouterState.of(context).uri.path;
    final available = [
      const Section('/', 'Главная', Icons.home, Permission.viewCatalog),
      ...sections.where((s) => auth.can(s.permission)),
    ];
    final selected = available.lastIndexWhere(
      (s) => s.path == '/' ? location == '/' : location.startsWith(s.path),
    );
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < compactWidth;
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: body,
      ),
    );
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (user != null && !compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text('${user.fullName} (${user.role.label})'),
              ),
            ),
          if (user != null && compact)
            Tooltip(
              message: '${user.fullName} (${user.role.label})',
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(reason: 'Вы вышли из системы.'),
          ),
        ],
      ),
      body:
          compact
              ? content
              : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SideNavigation(
                    sections: available,
                    selected: selected,
                    extended: width >= expandedWidth,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              ),
      bottomNavigationBar:
          compact
              ? _BottomNavigation(sections: available, selected: selected)
              : null,
    );
  }
}

class _SideNavigation extends StatelessWidget {
  final List<Section> sections;
  final int selected;
  final bool extended;

  const _SideNavigation({
    required this.sections,
    required this.selected,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: NavigationRail(
                  extended: extended,
                  labelType:
                      extended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                  selectedIndex: selected < 0 ? null : selected,
                  onDestinationSelected: (i) => context.go(sections[i].path),
                  destinations: [
                    for (final s in sections)
                      NavigationRailDestination(
                        icon: Icon(s.icon),
                        label: Text(s.label),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  static const _visible = 4;

  final List<Section> sections;
  final int selected;

  const _BottomNavigation({required this.sections, required this.selected});

  void _showMore(BuildContext context, List<Section> rest) {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final s in rest)
                  ListTile(
                    leading: Icon(s.icon),
                    title: Text(s.label),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      context.go(s.path);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = sections.length > _visible + 1;
    final shown = hasMore ? sections.take(_visible).toList() : sections;
    final rest = hasMore ? sections.skip(_visible).toList() : <Section>[];
    final index = selected >= shown.length ? shown.length : selected;
    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) {
        if (i < shown.length) {
          context.go(shown[i].path);
        } else {
          _showMore(context, rest);
        }
      },
      destinations: [
        for (final s in shown)
          NavigationDestination(icon: Icon(s.icon), label: s.label),
        if (hasMore)
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Ещё',
          ),
      ],
    );
  }
}
