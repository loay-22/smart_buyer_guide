import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/product_analysis_model.dart';
import '../../data/models/search_history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../widgets/app_scaffold.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyRepository = HistoryRepository();
  List<SearchHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _historyRepository.loadHistory();
    if (!mounted) return;
    setState(() => _history = items);
  }

  Future<void> _deleteOne(SearchHistoryEntry entry) async {
    await _historyRepository.deleteEntry(entry.id);
    await _loadHistory();
  }

  Future<void> _clearAll() async {
    await _historyRepository.clearAll();
    await _loadHistory();
  }

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_delete_all')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.translate('cancel'))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.translate('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      await _clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.translate('search_history'),
      actions: [
        IconButton(onPressed: _confirmDeleteAll, icon: const Icon(Icons.delete_sweep_outlined)),
      ],
      body: _history.isEmpty
          ? Center(child: Text(l10n.translate('no_history')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final entry = _history[index];
                final analysis = ProductAnalysisModel.fromJson(Map<String, dynamic>.from(entry.analysisJson));
                return Card(
                  child: ListTile(
                    leading: entry.imagePath != null && File(entry.imagePath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(entry.imagePath!), width: 56, height: 56, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.image_not_supported_outlined),
                    title: Text(entry.productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.timestamp.toLocal().toString().split(' ').first} • ${entry.timestamp.toLocal().toString().split(' ').last.split('.').first}'),
                        Text('${analysis.estimatedPriceNew.toStringAsFixed(0)} ${analysis.currency}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.translate('confirm_delete')),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.translate('cancel'))),
                              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.translate('yes'))),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _deleteOne(entry);
                        }
                      },
                    ),
                    onTap: () => context.push('/results', extra: {'analysis': analysis, 'historyEntry': entry}),
                  ),
                );
              },
            ),
    );
  }
}
