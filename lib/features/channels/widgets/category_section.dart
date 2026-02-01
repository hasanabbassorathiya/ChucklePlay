import 'package:lumio/core/widgets/content_card.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:lumio/models/category_view_model.dart';
import 'package:lumio/models/playlist_content_model.dart';

class CategorySection extends StatelessWidget {
  final CategoryViewModel category;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback? onSeeAllTap;
  final Function(ContentItem)? onContentTap;

  const CategorySection({
    super.key,
    required this.category,
    required this.cardWidth,
    required this.cardHeight,
    this.onSeeAllTap,
    this.onContentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.category.categoryName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllTap,
                  child: Text(
                    context.loc.see_all,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: category.contentItems.length,
              itemBuilder: (context, index) {
                final item = category.contentItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ContentCard(
                    content: item,
                    width: cardWidth,
                    onTap: () => onContentTap?.call(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
