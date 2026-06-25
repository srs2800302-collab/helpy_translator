import 'package:flutter/material.dart';

final class ProgressStatusCard extends StatelessWidget {
  const ProgressStatusCard({
    required this.title,
    required this.completed,
    required this.total,
    required this.currentPhrase,
    super.key,
  });

  final String title;
  final int completed;
  final int total;
  final String currentPhrase;

  @override
  Widget build(BuildContext context) {
    final double progress =
        total == 0 ? 0 : (completed / total).clamp(0.0, 1.0);
    final int percent = (progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: total == 0 ? null : progress),
            const SizedBox(height: 8),
            Text(total == 0 ? 'Подготовка...' : '$completed / $total · $percent%'),
            if (currentPhrase.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Текущая:\n$currentPhrase',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            const Text('Работает в фоне. Можно свернуть приложение.'),
          ],
        ),
      ),
    );
  }
}
