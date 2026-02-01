import 'package:lumio/repositories/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:provider/provider.dart';
import '../../controllers/xtream_code_home_controller.dart';

class CategorySettingsScreen extends StatefulWidget {
  final XtreamCodeHomeController controller;

  const CategorySettingsScreen({super.key, required this.controller});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  Set<String> _hiddenCategories = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenCategories();
  }

  Future<void> _loadHiddenCategories() async {
    final hidden = await UserPreferences.getHiddenCategories();
    setState(() {
      _hiddenCategories = hidden.toSet();
    });
  }

  Future<void> _toggleHidden(bool isVisible, String categoryId) async {
    setState(() {
      _hasChanges = true;
      if (isVisible) {
        _hiddenCategories.remove(categoryId);
      } else {
        _hiddenCategories.add(categoryId);
      }
    });
    await UserPreferences.setHiddenCategories(_hiddenCategories.toList());
    widget.controller.notifyListeners();
  }

  Future<void> _setAllCategoriesVisible(Iterable<String> ids, bool visible) async {
    setState(() {
      _hasChanges = true;
      if (visible) {
        _hiddenCategories.removeAll(ids);
      } else {
        _hiddenCategories.addAll(ids);
      }
    });
    await UserPreferences.setHiddenCategories(_hiddenCategories.toList());
    widget.controller.notifyListeners();
  }

  void _closeScreen(BuildContext context) {
    if (_hasChanges) {
      widget.controller.notifyListeners();
    }
    Navigator.pop(context, _hasChanges);
  }

  Widget _buildFocusableSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FocusableControlBuilder(
      onPressed: () => onChanged(!value),
      builder: (context, state) {
        final isFocused = state.isFocused;
        return Container(
          decoration: BoxDecoration(
            color: isFocused ? const Color(0xFFE50914).withOpacity(0.1) : null,
            border: isFocused
                ? const Border(
                    left: BorderSide(color: Color(0xFFE50914), width: 4),
                  )
                : null,
          ),
          child: SwitchListTile(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: isFocused ? FontWeight.bold : null,
                color: isFocused ? Colors.white : null,
              ),
            ),
            value: value,
            onChanged: onChanged,
            selected: isFocused,
          ),
        );
      },
    );
  }

  Widget _buildFocusableAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return FocusableControlBuilder(
      onPressed: onPressed,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isFocused ? const Color(0xFFE50914).withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(8),
            border: isFocused ? Border.all(color: const Color(0xFFE50914)) : null,
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(
              label,
              style: TextStyle(
                color: isFocused ? const Color(0xFFE50914) : null,
                fontWeight: isFocused ? FontWeight.bold : null,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasChanges);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.loc.hide_category),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, _hasChanges);
              },
            ),
          ),
          body: Consumer<XtreamCodeHomeController>(
            builder: (context, controller, _) {
              return ListView(
                children: [
                  ListTile(
                    title: Text(context.loc.live),
                    tileColor: Colors.black12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFocusableAction(
                        label: context.loc.select_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.liveCategories!.map((c) => c.category.categoryId),
                          true,
                        ),
                      ),
                      _buildFocusableAction(
                        label: context.loc.deselect_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.liveCategories!.map((c) => c.category.categoryId),
                          false,
                        ),
                      ),
                    ],
                  ),
                  ...?controller.liveCategories?.map((cat) {
                    final isHidden = _hiddenCategories.contains(cat.category.categoryId);
                    return _buildFocusableSwitchTile(
                      title: cat.category.categoryName,
                      value: !isHidden,
                      onChanged: (val) => _toggleHidden(val, cat.category.categoryId),
                    );
                  }),

                  const Divider(),
                  ListTile(
                    title: Text(context.loc.movies),
                    tileColor: Colors.black12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFocusableAction(
                        label: context.loc.select_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.movieCategories.map((c) => c.category.categoryId),
                          true,
                        ),
                      ),
                      _buildFocusableAction(
                        label: context.loc.deselect_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.movieCategories.map((c) => c.category.categoryId),
                          false,
                        ),
                      ),
                    ],
                  ),
                  ...controller.movieCategories.map((cat) {
                    final isHidden = _hiddenCategories.contains(cat.category.categoryId);
                    return _buildFocusableSwitchTile(
                      title: cat.category.categoryName,
                      value: !isHidden,
                      onChanged: (val) => _toggleHidden(val, cat.category.categoryId),
                    );
                  }),

                  const Divider(),
                  ListTile(
                    title: Text(context.loc.series_plural),
                    tileColor: Colors.black12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFocusableAction(
                        label: context.loc.select_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.seriesCategories.map((c) => c.category.categoryId),
                          true,
                        ),
                      ),
                      _buildFocusableAction(
                        label: context.loc.deselect_all,
                        onPressed: () => _setAllCategoriesVisible(
                          widget.controller.seriesCategories.map((c) => c.category.categoryId),
                          false,
                        ),
                      ),
                    ],
                  ),
                  ...controller.seriesCategories.map((cat) {
                    final isHidden = _hiddenCategories.contains(cat.category.categoryId);
                    return _buildFocusableSwitchTile(
                      title: cat.category.categoryName,
                      value: !isHidden,
                      onChanged: (val) => _toggleHidden(val, cat.category.categoryId),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
