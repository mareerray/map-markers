import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final List<String> suggestions;
  final void Function(String) onChanged;
  final void Function(String) onSuggestionTap;

  const SearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search places...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => controller.clear(),
                      )
                    : null,
          ),
          onChanged: onChanged,
        ),
        if (suggestions.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final parts = suggestions[i].split('|');
                return ListTile(
                  leading: const Icon(Icons.place, color: Colors.blue),
                  title: Text(parts[1]),
                  onTap: () => onSuggestionTap(parts[0]),
                );
              },
            ),
          ),
      ],
    );
  }
}
