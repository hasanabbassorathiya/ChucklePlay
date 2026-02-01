import 'package:lumio/controllers/m3u_home_controller.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/models/category_view_model.dart';
import 'package:lumio/models/playlist_content_model.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/utils/navigate_by_content_type.dart';
import 'package:lumio/utils/responsive_helper.dart';
import 'package:lumio/utils/app_themes.dart';
import 'package:lumio/features/home/widgets/playlist_switcher_button.dart';
import 'package:lumio/core/widgets/content_card.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:provider/provider.dart';

import '../channels/category_detail_screen.dart';
import '../channels/m3u_items_screen.dart';
import '../epg/epg_screen.dart';
import '../settings/settings_content.dart';

class M3UHomeScreen extends StatefulWidget {
  final Playlist playlist;

  const M3UHomeScreen({super.key, required this.playlist});

  @override
  State<M3UHomeScreen> createState() => _M3UHomeScreenState();
}

class _M3UHomeScreenState extends State<M3UHomeScreen> {
  late M3UHomeController _controller;
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = M3UHomeController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_NavItem> _getNavItems(BuildContext context) => [
        _NavItem(Icons.home_rounded, context.loc.home, 0),
        _NavItem(Icons.list_alt_rounded, context.loc.all, 1),
        _NavItem(Icons.live_tv_rounded, context.loc.live, 2),
        _NavItem(Icons.schedule_rounded, 'EPG', 3), // TODO: Localize
        _NavItem(Icons.movie_rounded, context.loc.movies, 4),
        _NavItem(Icons.tv_rounded, context.loc.series_plural, 5),
        _NavItem(Icons.settings_rounded, context.loc.settings, 6),
      ];

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems(context);
    final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isPhone = ResponsiveHelper.isPhone(context);
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<M3UHomeController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: const Center(
                child: CircularProgressIndicator(color: AppThemes.primaryAccent),
              ),
            );
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: isPhone
                ? AppBar(
                    backgroundColor: theme.appBarTheme.backgroundColor,
                    elevation: 0,
                    title: _buildLogo(compact: true),
                    centerTitle: true,
                    actions: const [
                      PlaylistSwitcherButton(compact: true),
                      SizedBox(width: 8),
                    ],
                  )
                : null,
            drawer: isPhone ? _buildMobileDrawer(navItems) : null,
            body: Row(
              children: [
                if (isDesktop) _buildSideBar(navItems),
                if (isTablet) _buildNavigationRail(navItems),
                Expanded(
                  child: _buildBody(controller, navItems),
                ),
              ],
            ),
            bottomNavigationBar: isPhone ? _buildBottomNavBar(navItems) : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(M3UHomeController controller, List<_NavItem> navItems) {
    final theme = Theme.of(context);
    switch (_selectedIndex) {
      case 0: // Home
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (controller.liveCategories != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = controller.liveCategories![index];
                    return _buildContentStrip(
                      category.category.categoryName,
                      category.contentItems,
                      category: category,
                    );
                  },
                  childCount: controller.liveCategories!.length,
                ),
              ),
            if (controller.vodCategories != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = controller.vodCategories![index];
                    return _buildContentStrip(
                      category.category.categoryName,
                      category.contentItems,
                      category: category,
                    );
                  },
                  childCount: controller.vodCategories!.length,
                ),
              ),
            if (controller.seriesCategories != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = controller.seriesCategories![index];
                    return _buildContentStrip(
                      category.category.categoryName,
                      category.contentItems,
                      category: category,
                    );
                  },
                  childCount: controller.seriesCategories!.length,
                ),
              ),
          ],
        );
      case 1: // All Channels
        return M3uItemsScreen(m3uItems: controller.m3uItems ?? []);
      case 2: // Live
        return _buildCategoryGrid(controller.liveCategories ?? []);
      case 3: // EPG
        return const EpgScreen();
      case 4: // Movies
        return _buildCategoryGrid(controller.vodCategories ?? []);
      case 5: // Series
        return _buildCategoryGrid(controller.seriesCategories ?? []);
      case 6: // Settings
        return const SettingsContent();
      default:
        return Center(
          child: Text(
            'Coming Soon: ${navItems[_selectedIndex].label}',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface),
          ),
        );
    }
  }

  Widget _buildCategoryGrid(List<CategoryViewModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildContentStrip(
          cat.category.categoryName,
          cat.contentItems,
          category: cat,
        );
      },
    );
  }

  Widget _buildContentStrip(
    String title,
    List<ContentItem> items, {
    CategoryViewModel? category,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
    final cardWidth = ResponsiveHelper.getStbCardWidth(context);
    final cardHeight = ResponsiveHelper.getCardHeight(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 40 : 20,
            32,
            isDesktop ? 40 : 20,
            16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (category != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryDetailScreen(category: category),
                      ),
                    );
                  },
                  child: Text(
                    context.loc.see_all,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ContentCard(
                  content: item,
                  width: cardWidth,
                  onTap: () => navigateByContentType(context, item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSideBar(List<_NavItem> navItems) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarExpanded = true),
      onExit: (_) => setState(() => _isSidebarExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSidebarExpanded ? 240 : 80,
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PlaylistSwitcherButton(isSidebarExpanded: _isSidebarExpanded),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (context, index) =>
                    _buildSideNavItem(navItems, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({bool compact = false}) {
    final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
    final expanded = compact ? false : (isDesktop ? _isSidebarExpanded : true);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 24 : 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill,
            color: AppThemes.primaryAccent,
            size: 32,
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            const Text(
              'LUMIO',
              style: TextStyle(
                color: AppThemes.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(List<_NavItem> navItems) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            child: Center(child: _buildLogo(compact: false)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color:
                        isSelected ? AppThemes.primaryAccent : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(List<_NavItem> navItems) {
    final theme = Theme.of(context);
    return NavigationRail(
      backgroundColor: theme.colorScheme.surface,
      selectedIconTheme: const IconThemeData(color: AppThemes.primaryAccent),
      unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      selectedLabelTextStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      labelType: NavigationRailLabelType.selected,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      leading: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Icon(
              Icons.play_circle_fill,
              color: AppThemes.primaryAccent,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          const PlaylistSwitcherButton(compact: true),
          const SizedBox(height: 8),
        ],
      ),
      destinations: navItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }

  Widget _buildSideNavItem(List<_NavItem> navItems, int index) {
    final item = navItems[index];
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return FocusableControlBuilder(
      onPressed: () => setState(() => _selectedIndex = index),
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: (isFocused || isSelected)
                  ? theme.colorScheme.onSurface.withOpacity(0.1)
                  : Colors.transparent,
              border: (isFocused || isSelected)
                  ? const Border(
                      left: BorderSide(color: AppThemes.primaryAccent, width: 4),
                    )
                  : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppThemes.primaryAccent.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: (isSelected || isFocused)
                      ? AppThemes.primaryAccent
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 28,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 20),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: (isSelected || isFocused)
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: (isSelected || isFocused)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar(List<_NavItem> navItems) {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: AppThemes.primaryAccent,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.7),
      currentIndex: _selectedIndex.clamp(0, 4),
      type: BottomNavigationBarType.fixed,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: navItems.take(5).map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem(this.icon, this.label, this.index);
}
