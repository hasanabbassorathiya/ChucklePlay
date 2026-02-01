import 'package:lumio/controllers/category_detail_controller.dart';
import 'package:lumio/features/channels/widgets/category_app_bar.dart';
import 'package:lumio/features/channels/widgets/content_grid.dart';
import 'package:lumio/features/channels/widgets/content_states.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:provider/provider.dart';
import 'package:lumio/models/category_view_model.dart';
import 'package:lumio/utils/navigate_by_content_type.dart';

class CategoryDetailScreen extends StatelessWidget {
  final CategoryViewModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryDetailController(category),
      child: const _CategoryDetailView(),
    );
  }
}

class _CategoryDetailView extends StatefulWidget {
  const _CategoryDetailView();

  @override
  State<_CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<_CategoryDetailView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryDetailController>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryDetailController>(
      builder: (context, controller, child) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              CategoryAppBar(
                title: controller.category.category.categoryName,
                isSearching: controller.isSearching,
                searchController: _searchController,
                onSearchStart: controller.startSearch,
                onSearchStop: () {
                  controller.stopSearch();
                  _searchController.clear();
                },
                onSearchChanged: controller.searchContent,
                onSortPressed: () => _showSortOptions(controller),
              ),
            ],
            body: _buildBody(controller),
          ),
        );
      },
    );
  }

  Widget _buildBody(CategoryDetailController controller) {
    if (controller.isLoading) return const LoadingState();
    if (controller.errorMessage != null) {
      return ErrorState(
        message: controller.errorMessage!,
        onRetry: controller.loadContent,
      );
    }
    if (controller.isEmpty) return const EmptyState();
    return Column(
      children: [
        if (controller.genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: _buildGenreSelector(controller),
          ),
        Expanded(
          child: ContentGrid(
            items: controller.displayItems,
            onItemTap: (item) => navigateByContentType(context, item),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(CategoryDetailController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildGenreChip(
            label: context.loc.all,
            isSelected: controller.selectedGenre == null,
            onSelected: () => controller.filterByGenre(null),
          ),
          ...controller.genres.map(
            (g) => _buildGenreChip(
              label: _capitalizeGenre(g),
              isSelected: controller.selectedGenre == g,
              onSelected: () => controller.filterByGenre(g),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FocusableControlBuilder(
        onPressed: onSelected,
        builder: (context, state) {
          final isFocused = state.isFocused;
          return AnimatedScale(
            scale: isFocused ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  color: (isFocused || isSelected) ? Colors.white : null,
                  fontWeight: (isFocused || isSelected) ? FontWeight.bold : null,
                ),
              ),
              selected: isSelected,
              selectedColor: isFocused ? const Color(0xFFE50914) : null,
              backgroundColor: isFocused ? const Color(0xFFE50914).withOpacity(0.5) : null,
              side: isFocused
                  ? const BorderSide(color: Color(0xFFE50914), width: 2)
                  : null,
              onSelected: (_) => onSelected(),
            ),
          );
        },
      ),
    );
  }

  void _showSortOptions(CategoryDetailController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption(
                context,
                title: 'A → Z',
                onTap: () {
                  controller.sortItems("ascending");
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                context,
                title: 'Z → A',
                onTap: () {
                  controller.sortItems("descending");
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                context,
                title: context.loc.release_date,
                icon: Icons.event,
                onTap: () {
                  controller.sortItems("release_date");
                  Navigator.pop(context);
                },
              ),
              _buildSortOption(
                context,
                title: context.loc.rating,
                icon: Icons.star_rate,
                onTap: () {
                  controller.sortItems("rating");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return FocusableControlBuilder(
      onPressed: onTap,
      builder: (context, state) {
        final isFocused = state.isFocused;
        final colorScheme = Theme.of(context).colorScheme;

        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? colorScheme.primary.withOpacity(0.1) : null,
              border: isFocused
                  ? Border(left: BorderSide(color: colorScheme.primary, width: 4))
                  : null,
            ),
            child: ListTile(
              leading: icon != null
                  ? Icon(icon, color: isFocused ? colorScheme.primary : null)
                  : const SizedBox(width: 24),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isFocused ? FontWeight.bold : null,
                  color: isFocused ? colorScheme.primary : null,
                ),
              ),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  String _capitalizeGenre(String genre) {
    if (genre.isEmpty) return genre;
    return genre
        .split(' ')
        .map((word) {
      if (word.isEmpty) return word;
      final first = word.characters.first.toUpperCase();
      final rest = word.characters.skip(1).join();
      return '$first$rest';
    })
        .join(' ');
  }
}