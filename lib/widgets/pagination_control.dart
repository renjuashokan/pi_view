import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final Function(int) onPageChanged;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0, // Add bottom padding to avoid FAB
        top: 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First page button
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed:
                  currentPage > 0 && !isLoading ? () => onPageChanged(0) : null,
              tooltip: 'First Page',
            ),
            // Previous page button
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 0 && !isLoading
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              tooltip: 'Previous Page',
            ),
            // Page indicator
            Container(
              constraints: const BoxConstraints(minWidth: 100),
              child: Text(
                'Page ${currentPage + 1} of $totalPages',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Next page button
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages - 1 && !isLoading
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              tooltip: 'Next Page',
            ),
            // Last page button
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: currentPage < totalPages - 1 && !isLoading
                  ? () => onPageChanged(totalPages - 1)
                  : null,
              tooltip: 'Last Page',
            ),
          ],
        ),
      ),
    );
  }
}
