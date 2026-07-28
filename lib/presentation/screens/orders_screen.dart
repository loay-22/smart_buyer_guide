import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _orders = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Orders',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final items = order['order_items'] as List<dynamic>? ?? [];
                    final totalAmount = order['total_amount']?.toString() ?? '0';
                    final status = (order['status'] ?? 'Pending').toString();
                    final createdAt = order['created_at']?.toString() ?? '';

                    return Card(
                      child: ListTile(
                        title: Text('Order #${order['id'] ?? index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items: ${items.length}'),
                            Text('Total: $totalAmount YER'),
                            Text('Placed: ${createdAt.isEmpty ? '—' : createdAt.substring(0, 10)}'),
                          ],
                        ),
                        trailing: Chip(label: Text(status)),
                      ),
                    );
                  },
                ),
    );
  }
}
