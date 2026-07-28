import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/product_analysis_model.dart';
import '../../data/models/search_history_entry.dart';
import '../widgets/app_scaffold.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.analysis, required this.historyEntry});

  final ProductAnalysisModel analysis;
  final SearchHistoryEntry historyEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.translate('app_title'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.productName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _InfoRow(label: l10n.translate('estimated_new_price'), value: '${analysis.estimatedPriceNew.toStringAsFixed(0)} ${analysis.currency}'),
                    _InfoRow(label: l10n.translate('estimated_used_price'), value: '${analysis.estimatedPriceUsed.toStringAsFixed(0)} ${analysis.currency}'),
                    if (historyEntry.budget != null) ...[
                      const SizedBox(height: 8),
                      Text(_budgetMessage(historyEntry.budget!, analysis.estimatedPriceNew, context), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(title: l10n.translate('advantages'), items: analysis.advantages),
            const SizedBox(height: 16),
            _SectionCard(title: l10n.translate('disadvantages'), items: analysis.disadvantages),
            if (analysis.recommendedProducts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l10n.translate('recommended_products'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...analysis.recommendedProducts.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('${item.newPrice.toStringAsFixed(0)} ${analysis.currency}'),
                            Text('${item.usedPrice.toStringAsFixed(0)} ${analysis.currency}'),
                            const SizedBox(height: 8),
                            _SectionCard(title: l10n.translate('advantages'), items: item.advantages, compact: true),
                            const SizedBox(height: 8),
                            _SectionCard(title: l10n.translate('disadvantages'), items: item.disadvantages, compact: true),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.translate('search')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _budgetMessage(double budget, double estimatedPrice, BuildContext context) {
  if (estimatedPrice <= budget) {
    return AppLocalizations.of(context).translate('budget_enough');
  }
  if (budget > 0 && estimatedPrice > budget * 1.15) {
    return AppLocalizations.of(context).translate('budget_low');
  }
  return AppLocalizations.of(context).translate('budget_high');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items, this.compact = false});

  final String title;
  final List<String> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('—')
            else
              ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
