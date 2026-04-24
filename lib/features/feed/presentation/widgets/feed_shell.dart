import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeedShell extends StatelessWidget {
  const FeedShell({required this.child, this.floatingActionButton, super.key});

  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final path = GoRouterState.of(context).uri.path;
    final canPopRoute = Navigator.of(context).canPop();

    return PopScope(
      canPop: path == '/' || canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && path != '/') {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          titleSpacing: DualioTheme.mobileMargin,
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(strings.appName),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 18),
              child: IconButton(
                tooltip: strings.settingsTab,
                onPressed: () => _openRoute(context, '/settings'),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: palette.pill,
                  child: const Icon(Icons.person_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
        body: child,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _BottomNav(strings: strings),
      ),
    );
  }
}

void _openRoute(BuildContext context, String route) {
  final currentPath = GoRouterState.of(context).uri.path;
  if (currentPath == route) {
    return;
  }
  if (route == '/') {
    context.go(route);
    return;
  }
  context.push(route);
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final path = GoRouterState.of(context).uri.path;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: palette.outline.withValues(alpha: 0.45))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavButton(icon: Icons.all_inbox_rounded, label: strings.feedTab, selected: path == '/', onTap: () => _openRoute(context, '/')),
              _NavButton(icon: Icons.search_rounded, label: strings.searchTab, selected: path == '/search', onTap: () => _openRoute(context, '/search')),
              _NavButton(icon: Icons.view_agenda_outlined, selectedIcon: Icons.view_agenda_rounded, label: strings.categoriesTab, selected: path == '/categories', onTap: () => _openRoute(context, '/categories')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.selected, required this.onTap, this.selectedIcon});

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final color = selected ? Theme.of(context).colorScheme.onSurface : palette.outline;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: IconButton(
        icon: Icon(selected ? selectedIcon ?? icon : icon),
        color: color,
        iconSize: selected ? 27 : 24,
        onPressed: onTap,
      ),
    );
  }
}
