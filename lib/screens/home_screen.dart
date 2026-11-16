import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/product.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _onRefresh() async {
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();
    await productProvider.loadCategories();
    await productProvider.loadProducts(
      categoryId: productProvider.selectedCategoryId,
    );
    await cartProvider.loadCart();
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  Future<void> _addToCart(Product product) async {
    final cart = context.read<CartProvider>();
    final success = await cart.addToCart(product.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.midnight : Colors.red.shade700,
        content: Text(
          success
              ? '${product.name} agregado al carrito'
              : (cart.error ?? 'No se pudo agregar'),
          style: const TextStyle(fontFamily: 'Inter'),
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final visible = productProvider.visibleProducts;
    final hasSearch = productProvider.searchQuery.trim().isNotEmpty;
    final featured = (!hasSearch && visible.isNotEmpty)
        ? visible.take(4).toList()
        : <Product>[];
    final featuredIds = featured.map((p) => p.id).toSet();
    // Evita duplicar en grid (y colisión de Hero tags) lo ya mostrado en Destacados.
    final catalogItems = featured.isEmpty
        ? visible
        : visible.where((p) => !featuredIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _StoreHeader(
                  userName: auth.user?.name ?? 'Usuario',
                  cartCount: cartProvider.itemCount,
                  searchController: _searchController,
                  showClear: productProvider.searchQuery.trim().isNotEmpty,
                  onSearchChanged: productProvider.setSearchQuery,
                  onSearchClear: () {
                    _searchController.clear();
                    productProvider.clearSearch();
                  },
                  onCartTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  onLogout: _logout,
                ),
              ),
              if (!hasSearch)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _PromoBanner(),
                  ),
                ),
              if (productProvider.categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: _CategoriesSection(productProvider: productProvider),
                ),
              if (featured.isNotEmpty)
                SliverToBoxAdapter(
                  child: _FeaturedSection(
                    products: featured,
                    onOpen: _openProduct,
                    onAdd: _addToCart,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Catálogo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '${visible.length}',
                          key: ValueKey(visible.length),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ..._buildCatalogSlivers(
                productProvider,
                visible,
                catalogItems,
                hasSearch,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCatalogSlivers(
    ProductProvider provider,
    List<Product> visible,
    List<Product> catalogItems,
    bool hasSearch,
  ) {
    if (provider.isLoading && provider.products.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (provider.error != null && provider.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.error_outline,
            title: 'No se pudo cargar el catálogo',
            message: provider.error!,
            actionLabel: 'Reintentar',
            onAction: () => provider.loadProducts(
              categoryId: provider.selectedCategoryId,
            ),
          ),
        ),
      ];
    }

    if (provider.products.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No hay productos disponibles',
            message: 'Vuelve a intentarlo más tarde.',
          ),
        ),
      ];
    }

    if (visible.isEmpty && hasSearch) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Sin resultados',
            message:
                'No encontramos productos para “${provider.searchQuery.trim()}”.',
            actionLabel: 'Limpiar búsqueda',
            onAction: () {
              _searchController.clear();
              provider.clearSearch();
            },
          ),
        ),
      ];
    }

    if (catalogItems.isEmpty) {
      return const [];
    }

    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _crossAxisCount(constraints.crossAxisExtent);
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.68,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = catalogItems[index];
                  return _StaggeredProduct(
                    index: index,
                    child: ProductCard(
                      product: product,
                      onTap: () => _openProduct(product),
                      onAddToCart: () => _addToCart(product),
                    ),
                  );
                },
                childCount: catalogItems.length,
              ),
            ),
          );
        },
      ),
    ];
  }
}

class _StoreHeader extends StatelessWidget {
  final String userName;
  final int cartCount;
  final TextEditingController searchController;
  final bool showClear;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onCartTap;
  final VoidCallback onLogout;

  const _StoreHeader({
    required this.userName,
    required this.cartCount,
    required this.searchController,
    required this.showClear,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onCartTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.midnight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Tienda',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Hola, $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.midnight,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Carrito',
                onPressed: onCartTap,
                icon: Badge(
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '$cartCount',
                      key: ValueKey(cartCount),
                    ),
                  ),
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppColors.accent,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.midnight,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar en el catálogo…',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.secondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.secondary,
              ),
              suffixIcon: showClear
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: onSearchClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.secondary,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&h=675&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.midnight,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: AppColors.midnight);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.midnight.withValues(alpha: 0.88),
                    AppColors.midnight.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NUEVA COLECCIÓN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Diseño que\nse siente premium',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explora categorías y encuentra lo esencial.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      // CTA visual: lleva el scroll a categorías (sin lógica nueva).
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      ),
                    ),
                    child: const Text(
                      'Explorar ahora',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final ProductProvider productProvider;

  const _CategoriesSection({required this.productProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Categorías',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              AllCategoriesChip(
                isSelected: productProvider.selectedCategoryId == null,
                onTap: () => productProvider.loadProducts(),
              ),
              ...productProvider.categories.map(
                (category) => CategoryChip(
                  category: category,
                  isSelected:
                      productProvider.selectedCategoryId == category.id,
                  onTap: () {
                    productProvider.loadProducts(categoryId: category.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onOpen;
  final Future<void> Function(Product) onAdd;

  const _FeaturedSection({
    required this.products,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Destacados',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 200,
                child: _StaggeredProduct(
                  index: index,
                  child: ProductCard(
                    product: product,
                    onTap: () => onOpen(product),
                    onAddToCart: () => onAdd(product),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Aparición progresiva suave de cada tarjeta.
class _StaggeredProduct extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredProduct({
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredProduct> createState() => _StaggeredProductState();
}

class _StaggeredProductState extends State<_StaggeredProduct>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 40 * (widget.index % 8));
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.secondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
