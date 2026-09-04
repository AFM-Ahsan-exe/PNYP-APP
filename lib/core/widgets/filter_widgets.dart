import 'package:flutter/material.dart';

enum SortOrder { ascending, descending }

class FilterChipGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onChanged;

  const FilterChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DateRangeFilter extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onRangeSelected;

  const DateRangeFilter({
    super.key,
    this.selectedRange,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              onRangeSelected(picked);
            }
          },
          icon: const Icon(Icons.date_range_rounded),
          label: Text(
            selectedRange != null
                ? '${selectedRange!.start.day}/${selectedRange!.start.month}/${selectedRange!.start.year} - ${selectedRange!.end.day}/${selectedRange!.end.month}/${selectedRange!.end.year}'
                : 'Select Date Range',
          ),
        ),
        if (selectedRange != null)
          TextButton.icon(
            onPressed: () => onRangeSelected(null),
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Clear'),
          ),
      ],
    );
  }
}

class SortOrderSelector extends StatelessWidget {
  final SortOrder sortOrder;
  final ValueChanged<SortOrder> onSortOrderChanged;

  const SortOrderSelector({
    super.key,
    required this.sortOrder,
    required this.onSortOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SortOrder>(
      segments: const [
        ButtonSegment(
          value: SortOrder.ascending,
          label: Text('Oldest'),
          icon: Icon(Icons.arrow_upward_rounded),
        ),
        ButtonSegment(
          value: SortOrder.descending,
          label: Text('Newest'),
          icon: Icon(Icons.arrow_downward_rounded),
        ),
      ],
      selected: {sortOrder},
      onSelectionChanged: (Set<SortOrder> newSelection) {
        onSortOrderChanged(newSelection.first);
      },
    );
  }
}
