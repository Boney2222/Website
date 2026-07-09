import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/api_config.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'services/api_service.dart';

void main() {
  runApp(const PanLatePyarApp());
}

class PanLatePyarApp extends StatelessWidget {
  const PanLatePyarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => ShopState()..bootstrap()),
      ],
      child: MaterialApp(
        title: 'PAN LATE PYAR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3E5C46),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFBF9F3),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class ShopState extends ChangeNotifier {
  final _api = ApiService();
  final List<CartItemModel> cart = [];
  final List<OrderModel> orders = [];
  List<ProductModel> products = [];
  List<CategoryModel> categories = [];
  UserModel? user;
  bool loading = true;
  bool usingMockData = false;
  String? error;
  int _cartId = 1000;

  bool get isLoggedIn => user != null;
  double get subtotal => cart.fold(0, (sum, item) => sum + item.lineTotal);
  double get tax => subtotal * 0.06;
  double get total => subtotal + tax;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    await Future.wait([loadCatalog(), restoreSession()]);
    loading = false;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    try {
      final categoryRows = await _api.get('categories/list.php') as List;
      final productRows = await _api.get('products/list.php') as List;
      categories = categoryRows
          .map((row) => CategoryModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      products = productRows
          .map((row) => ProductModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      usingMockData = false;
      error = null;
    } catch (exception) {
      categories = mockCategories;
      products = mockProducts;
      usingMockData = true;
      error = 'Backend unavailable, using mock data for navigation.';
    }
  }

  Future<void> restoreSession() async {
    try {
      final data = await _api.get('auth/me.php');
      final rawUser = data is Map && data['user'] is Map ? data['user'] : data;
      if (rawUser is Map) {
        user = UserModel.fromJson(Map<String, dynamic>.from(rawUser));
      }
    } catch (_) {
      user = null;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final data = await _api.post('auth/login.php', {
        'email': email,
        'password': password,
      });
      final rawUser = data is Map && data['user'] is Map ? data['user'] : data;
      user = UserModel.fromJson(Map<String, dynamic>.from(rawUser as Map));
      notifyListeners();
      return null;
    } catch (exception) {
      user = UserModel(id: 1, fullName: 'Demo Customer', email: email);
      usingMockData = true;
      notifyListeners();
      return 'Backend login failed, signed in with a demo session.';
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final data = await _api.post('auth/register.php', {
        'full_name': name,
        'email': email,
        'password': password,
        'phone': '',
      });
      final rawUser = data is Map && data['user'] is Map ? data['user'] : data;
      user = UserModel.fromJson(Map<String, dynamic>.from(rawUser as Map));
      notifyListeners();
      return null;
    } catch (_) {
      user = UserModel(id: 2, fullName: name, email: email);
      usingMockData = true;
      notifyListeners();
      return 'Backend registration failed, created a demo session.';
    }
  }

  Future<void> logout() async {
    await _api.get('auth/logout.php').catchError((_) => null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('php_session_cookie');
    user = null;
    cart.clear();
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      cart.add(CartItemModel(id: _cartId++, product: product, quantity: 1));
    } else {
      cart[index] = cart[index].copyWith(quantity: cart[index].quantity + 1);
    }
    notifyListeners();
  }

  void updateQuantity(CartItemModel item, int quantity) {
    if (quantity <= 0) {
      cart.removeWhere((line) => line.id == item.id);
    } else {
      final index = cart.indexWhere((line) => line.id == item.id);
      if (index != -1) cart[index] = item.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  OrderModel checkout({required String paymentMethod}) {
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch,
      code:
          'PP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      total: total,
      paymentMethod: paymentMethod,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    orders.insert(0, order);
    cart.clear();
    notifyListeners();
    return order;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final screens = [
      const HomeScreen(),
      const ProductListScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAN LATE PYAR'),
        actions: [
          if (state.usingMockData)
            IconButton(
              tooltip: 'Mock data active',
              onPressed: () =>
                  showMessage(context, state.error ?? 'Mock data active'),
              icon: const Icon(Icons.cloud_off_outlined),
            ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: screens[index],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${state.cart.length}'),
              isLabelVisible: state.cart.isNotEmpty,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final featured = state.products.take(4).toList();
    return RefreshIndicator(
      onRefresh: state.loadCatalog,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Thoughtful stationery for slower, better days.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text('API base: ${ApiConfig.baseUrl}'),
          if (state.usingMockData)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: InfoBanner(
                text: 'Backend is unavailable. Mock responses are active.',
              ),
            ),
          const SizedBox(height: 24),
          Text('Categories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.categories
                .map((category) => Chip(label: Text(category.name)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('Featured products',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final product in featured) ProductTile(product: product),
        ],
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String search = '';
  String category = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final filtered = state.products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(search.toLowerCase()) ||
              product.description.toLowerCase().contains(search.toLowerCase());
      final matchesCategory =
          category == 'all' || product.categorySlug == category;
      return matchesSearch && matchesCategory;
    }).toList();

    return RefreshIndicator(
      onRefresh: state.loadCatalog,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchBar(
            hintText: 'Search notebooks, pens, art supplies...',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => search = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: category == 'all',
                    label: const Text('All'),
                    onSelected: (_) => setState(() => category = 'all'),
                  ),
                ),
                for (final item in state.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: category == item.slug,
                      label: Text(item.name),
                      onSelected: (_) => setState(() => category = item.slug),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products found',
              message: 'Try another search or category.',
            )
          else
            for (final product in filtered) ProductTile(product: product),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductImage(url: product.imageUrl, size: 88),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.categoryName ?? 'Stationery'),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(product.price),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Add to cart',
                onPressed: product.inStock
                    ? () {
                        context.read<ShopState>().addToCart(product);
                        showMessage(context, 'Added ${product.name}');
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.product, super.key});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProductImage(url: product.imageUrl, size: 280),
          const SizedBox(height: 16),
          Text(product.categoryName ?? 'Stationery'),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 16),
          Text('Stock: ${product.stockQty}'),
          const SizedBox(height: 8),
          Text(
            money(product.price),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: product.inStock
                ? () {
                    context.read<ShopState>().addToCart(product);
                    showMessage(context, 'Added to cart');
                  }
                : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Add to cart'),
          ),
          const SizedBox(height: 24),
          Text('Recommended', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final related in context
              .watch<ShopState>()
              .products
              .where((item) => item.id != product.id)
              .take(2))
            ProductTile(product: related),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    if (state.cart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Add a few paper treasures from the shop.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in state.cart)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ProductImage(url: item.product.imageUrl, size: 56),
              title: Text(item.product.name),
              subtitle: Text(money(item.lineTotal)),
              trailing: QuantityStepper(item: item),
            ),
          ),
        SummaryCard(
            subtotal: state.subtotal, tax: state.tax, total: state.total),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          ),
          child: const Text('Checkout'),
        ),
      ],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final formKey = GlobalKey<FormState>();
  String paymentMethod = 'cod';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Recipient name'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              validator: requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Delivery address'),
              minLines: 2,
              maxLines: 3,
              validator: requiredValidator,
            ),
            const SizedBox(height: 24),
            Text('Payment method',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'cod',
                  icon: Icon(Icons.payments_outlined),
                  label: Text('COD'),
                ),
                ButtonSegment(
                  value: 'card',
                  icon: Icon(Icons.credit_card),
                  label: Text('Card'),
                ),
              ],
              selected: {paymentMethod},
              onSelectionChanged: (selection) =>
                  setState(() => paymentMethod = selection.first),
            ),
            if (paymentMethod == 'card') ...[
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cardholder name'),
                validator: paymentMethod == 'card' ? requiredValidator : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: '4111 1111 1111 1111',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberInputFormatter(),
                ],
                validator: paymentMethod == 'card' ? cardNumberValidator : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CardExpiryInputFormatter(),
                      ],
                      validator:
                          paymentMethod == 'card' ? cardExpiryValidator : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'CVC'),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator:
                          paymentMethod == 'card' ? cardCvvValidator : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SummaryCard(
              subtotal: context.watch<ShopState>().subtotal,
              tax: context.watch<ShopState>().tax,
              total: context.watch<ShopState>().total,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Place order'),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final order = context
                    .read<ShopState>()
                    .checkout(paymentMethod: paymentMethod);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderConfirmationScreen(order: order),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({required this.order, super.key});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  size: 72, color: Color(0xFF3E5C46)),
              const SizedBox(height: 16),
              Text(order.code,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Total: ${money(order.total)}'),
              const SizedBox(height: 8),
              Text('Payment: ${paymentLabel(order.paymentMethod)}'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    if (!state.isLoggedIn) return const LoginScreen();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 36,
          child: Text(state.user!.fullName.characters.first.toUpperCase()),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            state.user!.fullName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Center(child: Text(state.user!.email)),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit profile'),
          subtitle: const Text('Demo-ready local profile screen'),
          onTap: () =>
              showMessage(context, 'Profile editing is ready for API wiring.'),
        ),
        ListTile(
          leading: const Icon(Icons.history_outlined),
          title: const Text('Order history'),
          subtitle: Text('${state.orders.length} order(s)'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: state.logout,
        ),
      ],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController(text: 'customer@example.com');
  final password = TextEditingController(text: 'password123');
  bool signup = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                signup ? 'Create account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (signup)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: requiredValidator,
                ),
              if (signup) const SizedBox(height: 12),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => (value ?? '').length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(signup ? 'Sign up' : 'Login'),
              ),
              TextButton(
                onPressed: () => setState(() => signup = !signup),
                child: Text(
                    signup ? 'I already have an account' : 'Create account'),
              ),
              TextButton(
                onPressed: () => showMessage(
                  context,
                  'Forgot password needs a backend reset endpoint.',
                ),
                child: const Text('Forgot password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    final state = context.read<ShopState>();
    final message = signup
        ? await state.register(
            'Demo Customer', email.text.trim(), password.text)
        : await state.login(email.text.trim(), password.text);
    if (mounted && message != null) showMessage(context, message);
    if (mounted) setState(() => busy = false);
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<ShopState>().orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Orders placed during testing will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(order.code),
                    subtitle: Text(
                      '${order.status} - ${paymentLabel(order.paymentMethod)}',
                    ),
                    trailing: Text(money(order.total)),
                  ),
                );
              },
            ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({required this.item, super.key});
  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final state = context.read<ShopState>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => state.updateQuantity(item, item.quantity - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${item.quantity}'),
        IconButton(
          onPressed: () => state.updateQuantity(item, item.quantity + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.subtotal,
    required this.tax,
    required this.total,
    super.key,
  });

  final double subtotal;
  final double tax;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SummaryRow(label: 'Subtotal', value: money(subtotal)),
            SummaryRow(label: 'Tax', value: money(tax)),
            const Divider(),
            SummaryRow(label: 'Total', value: money(total), strong: true),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    super.key,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, required this.size, super.key});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? const ColoredBox(color: Color(0xFFEFE9D8))
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: Color(0xFFEFE9D8)),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Color(0xFFEFE9D8),
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String? requiredValidator(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Required' : null;

String? emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email';
  }
  return null;
}

String? cardNumberValidator(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length != 16 || !isValidCardNumber(digits)) {
    return 'Enter a valid card number';
  }
  return null;
}

bool isValidCardNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\d{16}$').hasMatch(digits)) return false;

  var sum = 0;
  var shouldDouble = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var digit = int.parse(digits[i]);
    if (shouldDouble) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    shouldDouble = !shouldDouble;
  }
  return sum % 10 == 0;
}

String? cardExpiryValidator(String? value) {
  final expiry = value?.trim() ?? '';
  if (!isValidCardExpiry(expiry)) {
    return 'Use MM/YY';
  }
  return null;
}

bool isValidCardExpiry(String value) {
  final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(value.trim());
  if (match == null) return false;

  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  final now = DateTime.now();
  return year > now.year || (year == now.year && month >= now.month);
}

String? cardCvvValidator(String? value) {
  final cvv = value?.trim() ?? '';
  if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
    return 'Enter CVV';
  }
  return null;
}

String paymentLabel(String value) =>
    value == 'card' ? 'Credit / Debit card' : 'Cash on delivery';

String money(double value) => 'MMK ${value.toStringAsFixed(2)}';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

const mockCategories = [
  CategoryModel(
      id: 1, name: 'Notebooks & Journals', slug: 'notebooks', icon: 'NB'),
  CategoryModel(
      id: 2, name: 'Pens & Pencils', slug: 'pens-pencils', icon: 'PN'),
  CategoryModel(id: 3, name: 'Art Supplies', slug: 'art-supplies', icon: 'AR'),
  CategoryModel(
      id: 4, name: 'Desk Accessories', slug: 'desk-accessories', icon: 'DA'),
];

const mockProducts = [
  ProductModel(
    id: 1,
    categoryId: 1,
    categoryName: 'Notebooks & Journals',
    categorySlug: 'notebooks',
    name: 'Kraft Cover Dot Journal',
    description: 'Dot-grid pages under a soft kraft cover.',
    price: 28900.00,
    stockQty: 34,
    imageUrl:
        'https://images.unsplash.com/photo-1531346878377-a5be20888e57?auto=format&fit=crop&w=700&q=75',
  ),
  ProductModel(
    id: 2,
    categoryId: 2,
    categoryName: 'Pens & Pencils',
    categorySlug: 'pens-pencils',
    name: 'Brass Fountain Pen',
    description: 'A weighty brass fountain pen with a starter ink cartridge.',
    price: 45000,
    stockQty: 8,
    imageUrl:
        'https://images.unsplash.com/photo-1583485088034-697b5bc36b3b?auto=format&fit=crop&w=700&q=75',
  ),
  ProductModel(
    id: 3,
    categoryId: 3,
    categoryName: 'Art Supplies',
    categorySlug: 'art-supplies',
    name: 'Watercolour Pencil Set',
    description: 'Twenty-four shades for sketching and wet blending.',
    price: 39900.00,
    stockQty: 20,
    imageUrl:
        'https://images.unsplash.com/photo-1607166452427-7e4477079cb9?auto=format&fit=crop&w=700&q=75',
  ),
  ProductModel(
    id: 4,
    categoryId: 4,
    categoryName: 'Desk Accessories',
    categorySlug: 'desk-accessories',
    name: 'Woven Desk Organiser',
    description: 'Four compartments for pens, clips, and desk tools.',
    price: 32000,
    stockQty: 15,
    imageUrl:
        'https://images.unsplash.com/photo-1517842645767-c639042777db?auto=format&fit=crop&w=700&q=75',
  ),
];
