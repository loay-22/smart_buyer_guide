import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product_model.dart';
import '../../data/models/search_history_entry.dart';
import '../../data/repositories/product_catalog_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../widgets/app_scaffold.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _picker = ImagePicker();
  final _repository = ProductRepository();
  final _historyRepository = HistoryRepository();
  late final ProductCatalogRepository _catalogRepository;

  String? _imagePath;
  bool _isLoading = false;
  String? _errorMessage;
  final List<CartItem> _cartItems = [];
  bool _isCheckingOut = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Electronics'];

  @override
  void initState() {
    super.initState();
    _catalogRepository = ProductCatalogRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _budgetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }
      setState(() {
        _imagePath = image.path;
      });
    } catch (_) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).translate('cancel');
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productName = _productNameController.text.trim();
    final budgetText = _budgetController.text.trim();
    final hasName = productName.isNotEmpty;
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;

    if (!hasName && !hasImage) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).translate('validation_message');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
      final analysis = await _repository.analyzeProduct(
        productName: productName,
        imagePath: _imagePath,
        budget: budget,
      );

      final entry = SearchHistoryEntry(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        productName: analysis.productName.isEmpty ? productName : analysis.productName,
        imagePath: _imagePath,
        budget: budget,
        analysisJson: analysis.toJson(),
      );
      await _historyRepository.addEntry(entry);

      if (!mounted) return;
      context.push('/results', extra: {
        'analysis': analysis,
        'historyEntry': entry,
      });
    } on NetworkException catch (e) {
      setState(() => _errorMessage = e.message);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } on InvalidJsonException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = AppLocalizations.of(context).translate('api_error'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCart(Product product) {
    setState(() {
      CartItem? existing;
      for (final item in _cartItems) {
        if (item.product.id == product.id) {
          existing = item;
          break;
        }
      }

      if (existing != null) {
        existing.quantity += 1;
      } else {
        _cartItems.add(CartItem(product: product));
      }
    });
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(product.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(product.description),
            const SizedBox(height: 8),
            Text('${product.price.toStringAsFixed(0)} YER', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          FilledButton(onPressed: () {
            Navigator.of(context).pop();
            _addToCart(product);
          }, child: const Text('Add to Cart')),
        ],
      ),
    );
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) {
      return;
    }

    setState(() {
      _isCheckingOut = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final orderItems = _cartItems.map((item) => {
        'product_id': item.product.id,
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
      }).toList();

      final totalAmount = _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

      await Supabase.instance.client.from('orders').insert({
        'user_id': userId,
        'order_items': orderItems,
        'total_amount': totalAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _cartItems.clear();
        _errorMessage = 'Order placed successfully';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to place order';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit app?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: AppScaffold(
        title: l10n.translate('app_title'),
      actions: [
        IconButton(
          onPressed: () => context.push('/orders'),
          icon: const Icon(Icons.receipt_long_outlined),
          tooltip: 'Orders',
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
        ),
        IconButton(
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.history),
          tooltip: l10n.translate('history'),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) => _buildCartSheet(),
            );
          },
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
        ),
      ],
        body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    child: Lottie.asset('assets/json/shopping.json'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search products',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Product>>(
                    stream: _catalogRepository.streamProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final products = (snapshot.data ?? []).where((product) {
                        final matchesCategory = _selectedCategory == 'All' || product.category.toLowerCase() == _selectedCategory.toLowerCase();
                        final searchText = _searchController.text.toLowerCase();
                        final matchesSearch = searchText.isEmpty || product.name.toLowerCase().contains(searchText);
                        return matchesCategory && matchesSearch;
                      }).toList();

                      if (products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No matching products found.'),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Shop', style: Theme.of(context).textTheme.titleLarge),
                              const Spacer(),
                              Text('${products.length} items', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                child: InkWell(
                                  onTap: () => _showProductDetails(product),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: product.imageUrl.isEmpty
                                                ? Icon(Icons.inventory_2_outlined, size: 60, color: Theme.of(context).colorScheme.primary)
                                                : Image.network(
                                                    product.imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                                        const SizedBox(height: 4),
                                        Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                                        const SizedBox(height: 8),
                                        Text('${product.price.toStringAsFixed(0)} YER', style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 8),
                                        FilledButton.icon(
                                          onPressed: () => _addToCart(product),
                                          icon: const Icon(Icons.add_shopping_cart_rounded),
                                          label: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                    ),
                  Text(l10n.translate('product_name'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _productNameController,
                    textDirection: Directionality.of(context) == TextDirection.rtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(hintText: l10n.translate('product_name_hint')),
                    validator: (value) => (value == null || value.trim().isEmpty) && _imagePath == null
                        ? l10n.translate('validation_message')
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.translate('product_image'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (_imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_imagePath!), height: 180, fit: BoxFit.cover),
                          )
                        else
                          Icon(Icons.image_outlined, size: 70, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(l10n.translate('choose_image')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.translate('budget'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(hintText: l10n.translate('budget_hint')),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l10n.translate('search')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 140, width: 140, child: Lottie.asset('assets/json/shopping.json')),
                          const SizedBox(height: 16),
                          Text(l10n.translate('loading')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/ai-chat'),
          icon: SizedBox(height: 32, width: 32, child: Lottie.asset('assets/json/ai.json')),
          label: const Text('AI Assistant'),
        ),
      ),
    );
  }

  Widget _buildCartSheet() {
    final total = _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Cart', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.product.name),
                            subtitle: Text('${item.product.price.toStringAsFixed(0)} YER each'),
                            trailing: SizedBox(
                              width: 140,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          item.quantity -= 1;
                                        } else {
                                          _cartItems.removeAt(index);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        item.quantity += 1;
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('${total.toStringAsFixed(0)} YER', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isCheckingOut ? null : () async {
                  await _checkout();
                  if (mounted && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.credit_card_rounded),
                label: Text(_isCheckingOut ? 'Placing order...' : 'Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
