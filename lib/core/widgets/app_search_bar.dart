import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? query;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.query,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        textField: true,
        label: hintText,
        child: TextField(
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: (query != null && query!.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
