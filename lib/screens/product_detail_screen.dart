import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  bool _adding = false;
  bool _justAdded = false;
  bool _entryStarted = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() {
      _adding = true;
      _justAdded = false;
    });

    final cart = context.read<CartProvider>();
    final success = await cart.addToCart(
      widget.productId,
      quantity: _quantity,
    );

    if (!mounted) return;

    setState(() {
      _adding = false;
      _justAdded = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.midnight : Colors.red.shade700,
        content: Text(
          success
              ? 'Agregado al carrito ($_quantity)'
              : (cart.error ?? 'Error al agregar'),
          style: const TextStyle(fontFamily: 'Inter'),
        ),
      ),
    );

    if (success) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _justAdded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final product = provider.selectedProduct;

    if (!_entryStarted &&
        product != null &&
        product.id == widget.productId &&
        !provider.isLoading) {
      _entryStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entryController.forward();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: provider.isLoading && product == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : provider.error != null && product == null
                ? _ErrorBody(
                    message: provider.error!,
                    onRetry: () {
                      provider.loadProductDetail(widget.productId);
                    },
                  )
                : product == null
                    ? const Center(
                        child: Text(
                          'Producto no encontrado',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.midnight,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _DetailTopBar(
                            cartCount: cart.itemCount,
                            onBack: () => Navigator.pop(context),
                            onCart: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: FadeTransition(
                                opacity: _fadeIn,
                                child: SlideTransition(
                                  position: _slideIn,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _ProductHeroImage(product: product),
                                      const SizedBox(height: 20),
                                      if (product.categoryName != null) ...[
                                        _CategoryBadge(
                                          label: product.categoryName!,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 28,
                                          height: 1.15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.midnight,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      const Text(
                                        'Descripción',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.midnight,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.description ??
                                            'Sin descripción',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          height: 1.5,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      const Text(
                                        'Cantidad',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.midnight,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _QuantitySelector(
                                        quantity: _quantity,
                                        onDecrease: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity -= 1);
                                          }
                                        },
                                        onIncrease: () {
                                          setState(() => _quantity += 1);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _AddToCartBar(
                            adding: _adding,
                            justAdded: _justAdded,
                            quantity: _quantity,
                            unitPrice: product.price,
                            onPressed: _addToCart,
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onCart;

  const _DetailTopBar({
    required this.cartCount,
    required this.onBack,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Regresar',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.midnight),
          ),
          const Expanded(
            child: Text(
              'Detalle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.midnight,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Carrito',
            onPressed: onCart,
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              backgroundColor: AppColors.accent,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  final Product product;

  const _ProductHeroImage({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Hero(
      tag: 'product-image-${product.id}',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.midnight.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 56,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 56,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Disminuir',
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.midnight,
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.midnight,
          ),
        ],
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final bool adding;
  final bool justAdded;
  final int quantity;
  final double unitPrice;
  final VoidCallback onPressed;

  const _AddToCartBar({
    required this.adding,
    required this.justAdded,
    required this.quantity,
    required this.unitPrice,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final total = unitPrice * quantity;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      '\$${total.toStringAsFixed(2)}',
                      key: ValueKey(total),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 52,
              decoration: BoxDecoration(
                color: justAdded ? AppColors.accent : AppColors.primary,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: adding ? null : onPressed,
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: adding
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  justAdded
                                      ? Icons.check_rounded
                                      : Icons.add_shopping_cart_rounded,
                                  key: ValueKey(justAdded ? 'ok' : 'cart'),
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            justAdded ? 'Agregado' : 'Agregar al carrito',
                            key: ValueKey(justAdded ? 'added' : 'add'),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
