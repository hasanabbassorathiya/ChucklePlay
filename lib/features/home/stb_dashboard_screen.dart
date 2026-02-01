import 'package:lumio/core/widgets/content_card.dart';
import 'package:lumio/controllers/favorites_controller.dart';
import 'package:lumio/models/category_view_model.dart';
import 'package:lumio/features/home/widgets/favorites_section.dart';
import 'package:lumio/features/home/widgets/watch_history_section.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/models/playlist_content_model.dart';
import 'package:lumio/controllers/stb_dashboard_controller.dart';
import 'package:lumio/utils/responsive_helper.dart';
import 'package:lumio/utils/navigate_by_content_type.dart';
import 'package:lumio/features/home/watch_history_screen.dart';
import 'package:lumio/features/settings/settings_content.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/features/channels/category_detail_screen.dart';
import 'package:lumio/features/channels/m3u_items_screen.dart';
import 'package:lumio/services/app_state.dart';
import 'package:lumio/models/watch_history.dart';
import 'package:lumio/utils/get_playlist_type.dart';
import 'package:lumio/utils/app_themes.dart';
import 'package:lumio/features/home/widgets/playlist_switcher_button.dart';

class StbDashboardScreen extends StatefulWidget {
  final Playlist playlist;

  const StbDashboardScreen({super.key, required this.playlist});

  @override
  State<StbDashboardScreen> createState() => _StbDashboardScreenState();
}

class _StbDashboardScreenState extends State<StbDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;
  late StbDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StbDashboardController();
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
        _NavItem(Icons.live_tv_rounded, context.loc.live, 1),
        _NavItem(Icons.movie_rounded, context.loc.movies, 2),
        _NavItem(Icons.tv_rounded, context.loc.series_plural, 3),
        _NavItem(Icons.history_rounded, context.loc.history, 4),
        _NavItem(Icons.favorite_rounded, context.loc.favorites, 5),
        _NavItem(Icons.settings_rounded, context.loc.settings, 6),
      ];

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems(context);
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<StbDashboardController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: const Center(
                child: CircularProgressIndicator(color: AppThemes.primaryAccent),
              ),
            );
          }

          final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
          final isTablet = ResponsiveHelper.isTablet(context);
          final isPhone = ResponsiveHelper.isPhone(context);

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

  Widget _buildBody(StbDashboardController controller, List<_NavItem> navItems) {
    final theme = Theme.of(context);
    switch (_selectedIndex) {
      case 0: // Home
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroSection(controller.featuredContent),
            _buildContentRows(controller),
          ],
        );
      case 1: // Live TV
        return _buildCategoryGrid(controller.liveCategories);
      case 2: // Movies
        return _buildCategoryGrid(controller.movieCategories);
      case 3: // Series
        return _buildCategoryGrid(controller.seriesCategories);
      case 4: // History
        return WatchHistoryScreen(playlistId: widget.playlist.id);
      case 5: // Favorites
        return _buildFavoritesPage();
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

  Widget _buildFavoritesPage() {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => FavoritesController()..loadFavorites(),
      child: Consumer<FavoritesController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppThemes.primaryAccent));
          }
          if (controller.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz favori bulunamadı',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: FavoritesSection(
              favorites: controller.favorites,
              cardWidth: ResponsiveHelper.getStbCardWidth(context),
              cardHeight: ResponsiveHelper.getCardHeight(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(List<CategoryViewModel> categories) {
    final theme = Theme.of(context);
    final isM3uPlaylist = isM3u;
    return Column(
      children: [
        if (isM3uPlaylist)
          Padding(
            padding: const EdgeInsets.all(24),
            child: FocusableControlBuilder(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => M3uItemsScreen(m3uItems: AppState.m3uItems ?? []),
                  ),
                );
              },
              builder: (context, state) {
                final isFocused = state.isFocused;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isFocused ? AppThemes.primaryAccent : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: isFocused ? Colors.white : AppThemes.primaryAccent),
                      const SizedBox(width: 16),
                      Text(
                        context.loc.see_all,
                        style: TextStyle(
                          color: isFocused ? Colors.white : theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildContentStrip(cat.category.categoryName, cat.contentItems, category: cat);
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
                itemBuilder: (context, index) => _buildSideNavItem(navItems, index),
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
                    color: isSelected ? AppThemes.primaryAccent : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              color: (isFocused || isSelected) ? theme.colorScheme.onSurface.withOpacity(0.1) : Colors.transparent,
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
                      color: (isSelected || isFocused) ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight:
                          (isSelected || isFocused) ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildHeroSection(ContentItem? featured) {
    final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
    final heroHeight = ResponsiveHelper.getHeroHeight(context);
    final titleSize = ResponsiveHelper.getHeroTitleSize(context);
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        height: heroHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withOpacity(0.1),
              theme.scaffoldBackgroundColor.withOpacity(0.8),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: featured != null && featured.imagePath.isNotEmpty
                    ? Image.network(
                        featured.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildHeroPlaceholder(),
                      )
                    : _buildHeroPlaceholder(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: isDesktop ? 40 : 20,
              right: isDesktop ? null : 20,
              bottom: isDesktop ? 60 : 30,
              child: SizedBox(
                width: isDesktop ? 600 : null,
                child: Column(
                  crossAxisAlignment:
                      isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text(
                      featured?.contentType.name.toUpperCase() ?? 'RECOMMENDED',
                      style: const TextStyle(
                        color: AppThemes.primaryAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      featured?.name ?? 'Discover Great Content',
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: isDesktop
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        FocusableControlBuilder(
                          onPressed: () {
                            if (featured != null) {
                              navigateByContentType(context, featured);
                            }
                          },
                          builder: (context, state) {
                            return AnimatedScale(
                              scale: state.isFocused ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 32 : 20,
                                  vertical: isDesktop ? 16 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isFocused ? AppThemes.primaryAccent : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: state.isFocused
                                      ? Border.all(color: Colors.white, width: 2)
                                      : null,
                                  boxShadow: state.isFocused
                                      ? [
                                          BoxShadow(
                                            color: AppThemes.primaryAccent.withOpacity(0.5),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: state.isFocused ? Colors.white : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Play Now',
                                      style: TextStyle(
                                        color: state.isFocused ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        FocusableControlBuilder(
                          onPressed: () {},
                          builder: (context, state) {
                            return AnimatedScale(
                              scale: state.isFocused ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 32 : 20,
                                  vertical: isDesktop ? 16 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isFocused
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: state.isFocused ? AppThemes.primaryAccent : Colors.white,
                                    width: state.isFocused ? 2 : 1,
                                  ),
                                  boxShadow: state.isFocused
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'More Info',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.movie_filter_outlined,
          size: 100,
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildContentRows(StbDashboardController controller) {
    final cardWidth = ResponsiveHelper.getStbCardWidth(context);
    final cardHeight = ResponsiveHelper.getCardHeight(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        if (controller.recentlyWatched.isNotEmpty)
          WatchHistorySection(
            title: context.loc.history,
            histories: controller.recentlyWatched
                .map((item) => WatchHistory(
                      playlistId: widget.playlist.id,
                      contentType: item.contentType,
                      streamId: item.id,
                      lastWatched: DateTime.now(),
                      title: item.name,
                      imagePath: item.imagePath,
                    ))
                .toList(),
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            onHistoryTap: (history) {
              final item = controller.recentlyWatched.firstWhere((i) => i.id == history.streamId);
              navigateByContentType(context, item);
            },
          ),
        if (controller.liveCategories.isNotEmpty)
          ...controller.liveCategories.take(3).map(
                (c) => _buildContentStrip(c.category.categoryName, c.contentItems, category: c),
              ),
        if (controller.movieCategories.isNotEmpty)
          ...controller.movieCategories.take(3).map(
                (c) => _buildContentStrip(c.category.categoryName, c.contentItems, category: c),
              ),
        if (controller.seriesCategories.isNotEmpty)
          ...controller.seriesCategories.take(3).map(
                (c) => _buildContentStrip(c.category.categoryName, c.contentItems, category: c),
              ),
        const SizedBox(height: 60),
      ]),
    );
  }

  Widget _buildContentStrip(String title, List<ContentItem> items, {CategoryViewModel? category}) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDesktop = ResponsiveHelper.isDesktopOrTV(context);
    final cardWidth = ResponsiveHelper.getStbCardWidth(context);
    final cardHeight = ResponsiveHelper.getCardHeight(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 20, 32, isDesktop ? 40 : 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (category != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(category: category),
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
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem(this.icon, this.label, this.index);
}
