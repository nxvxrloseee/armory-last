import 'package:flutter/material.dart';

import '../state/load_status.dart';

class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.builder,
    this.emptyMessage = 'Ничего не найдено',
    this.onRetry,
  });

  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final WidgetBuilder builder;
  final String emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      case LoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text(error ?? 'Произошла ошибка', textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ],
            ),
          ),
        );
      case LoadStatus.success:
        if (isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 40),
                  const SizedBox(height: 12),
                  Text(emptyMessage, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return builder(context);
    }
  }
}
