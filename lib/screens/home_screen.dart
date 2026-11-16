import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
      context.read<CartProvider>().loadCart();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.read<CartProvider>().clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${auth.user?.name ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${cartProvider.itemCount}'),
              isLabelVisible: cartProvider.itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.loadCategories();
          await productProvider.loadProducts(
            categoryId: productProvider.selectedCategoryId,
          );
          await cartProvider.loadCart();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (productProvider.categories.isNotEmpty)
              // Altura mínima para FilterChip con avatar de imagen (sin rediseñar el layout).
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: productProvider.selectedCategoryId == null,
                        onSelected: (_) {
                          productProvider.loadProducts();
                        },
                      ),
                    ),
                    ...productProvider.categories.map(
                      (category) => CategoryChip(
                        category: category,
                        isSelected: productProvider.selectedCategoryId == category.id,
                        onTap: () {
                          productProvider.loadProducts(categoryId: category.id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildProductList(productProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(ProductProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadProducts(
                categoryId: provider.selectedCategoryId,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final product = provider.products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            );
          },
        );
      },
    );
  }
}
