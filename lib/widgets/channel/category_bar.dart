import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class CategoryBar extends StatelessWidget {
  final List<StreamCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Pill(
              label: 'All',
              selected: selectedId.isEmpty,
              onTap: () => onSelect(''),
            );
          }
          final cat = categories[index - 1];
          return _Pill(
            label: cat.categoryName,
            selected: selectedId == cat.categoryId,
            onTap: () => onSelect(cat.categoryId),
          );
        },
      ),
    );
  }
}

class _Pill extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        // Let arrow keys pass through for Flutter directional traversal
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? UhvaColors.primary
                : _focused
                    ? UhvaColors.primary.withValues(alpha: 0.25)
                    : UhvaColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused ? UhvaColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: (widget.selected || _focused)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: (widget.selected || _focused)
                  ? Colors.white
                  : UhvaColors.onSurfaceMuted,
            ),
          ),
        ),
      ),
    );
  }
}
