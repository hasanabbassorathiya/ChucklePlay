import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';

class CategoryAppBar extends StatelessWidget {
  final String title;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onSearchStart;
  final VoidCallback onSearchStop;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onSortPressed;

  const CategoryAppBar({
    super.key,
    required this.title,
    required this.isSearching,
    required this.searchController,
    required this.onSearchStart,
    required this.onSearchStop,
    required this.onSearchChanged,
    this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: isSearching ? _buildSearchField(context) : SelectableText(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (onSortPressed != null)
          _buildActionButton(
            icon: Icons.sort,
            onPressed: onSortPressed!,
          ),
        _buildActionButton(
          icon: isSearching ? Icons.clear : Icons.search,
          onPressed: isSearching ? onSearchStop : onSearchStart,
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed}) {
    return FocusableControlBuilder(
      onPressed: onPressed,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFocused ? Colors.white.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: isFocused
                  ? Border.all(color: const Color(0xFFE50914), width: 2)
                  : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: context.loc.search,
        border: InputBorder.none,
      ),
      autofocus: true,
      onChanged: onSearchChanged,
    );
  }
}
