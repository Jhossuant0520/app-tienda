import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  Future<void> _addToCart() async {
    final cart = context.read<CartProvider>();
    final success = await cart.addToCart(widget.productId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Producto agregado al carrito' : (cart.error ?? 'Error al agregar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.selectedProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          provider.loadProductDetail(widget.productId);
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : product == null
                  ? const Center(child: Text('Producto no encontrado'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.imageUrl != null)
                            Image.network(
                              product.imageUrl!,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 250,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 64),
                              ),
                            )
                          else
                            Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image, size: 64)),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (product.categoryName != null)
                                  Chip(label: Text(product.categoryName!)),
                                const SizedBox(height: 16),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Descripción',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description ?? 'Sin descripción',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: product != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar al carrito'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
