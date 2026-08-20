import 'package:flutter/material.dart';

/// Screen header with title and description
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    );
  }
}

/// Filter bar component
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    this.searchHint = 'Cari...',
    this.onSearchChanged,
    this.searchValue,
    this.filters = const [],
    this.useDropdown = false,
    this.onFilterTap,
  });

  final String searchHint;
  final void Function(String)? onSearchChanged;
  final String? searchValue;
  final List<FilterItem> filters;
  final bool useDropdown;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: useDropdown
                ? DropdownButtonFormField<String>(
                    initialValue: filters
                        .where((filter) => filter.isSelected)
                        .firstOrNull
                        ?.value,
                    decoration: const InputDecoration(
                      labelText: 'Filter Puskesmas',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      for (final filter in filters)
                        DropdownMenuItem(
                          value: filter.value,
                          child: Text(
                            filter.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      final selected = filters.firstWhere(
                        (filter) => filter.value == value,
                      );
                      selected.onSelected?.call(true);
                    },
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in filters)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter.label),
                              onSelected: filter.onSelected,
                              selected: filter.isSelected,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (onFilterTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune),
              tooltip: 'Filter Lanjutan',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FilterItem {
  FilterItem({
    required this.label,
    this.value,
    this.isSelected = false,
    this.onSelected,
  });

  final String label;
  final String? value;
  final bool isSelected;
  final void Function(bool)? onSelected;
}

/// Status badge for showing status in tables
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.onTap,
  });

  final String label;
  final StatusType status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case StatusType.active:
        backgroundColor = Colors.green.shade50;
        foregroundColor = Colors.green.shade700;
      case StatusType.inactive:
        backgroundColor = Colors.red.shade50;
        foregroundColor = Colors.red.shade700;
      case StatusType.pending:
        backgroundColor = Colors.orange.shade50;
        foregroundColor = Colors.orange.shade700;
      case StatusType.draft:
        backgroundColor = Colors.grey.shade100;
        foregroundColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum StatusType { active, inactive, pending, draft }

/// Card with consistent styling for admin portal
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
