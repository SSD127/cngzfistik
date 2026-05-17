import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'theme_provider.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/customers/presentation/customer_list_screen.dart';
import '../features/customers/presentation/customer_detail_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/inventory/presentation/inventory_deposit_screen.dart';
import '../features/sales/presentation/new_sale_screen.dart';
import '../features/purchases/presentation/new_purchase_screen.dart';
import '../features/cash/presentation/cash_deposit_screen.dart';
import '../features/cash/presentation/cash_withdrawal_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/reports/presentation/monthly_report_screen.dart';
import '../features/reports/presentation/cash_flow_report_screen.dart';
import '../features/reports/presentation/expense_report_screen.dart';
import '../features/reports/presentation/stock_report_screen.dart';
import '../features/vault/presentation/vault_screen.dart';
import '../features/pistachio_types/presentation/pistachio_types_screen.dart';
import '../features/customer_page/presentation/customer_page_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

part 'router.g.dart';

// Router bir kez oluşturulur; auth değişimlerinde refreshListenable üzerinden
// redirect yeniden değerlendirilir — GoRouter hiçbir zaman yeniden yaratılmaz.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final authNotifier = _GoRouterAuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Auth henüz yüklenmediyse yönlendirme yapma (beyaz ekran önlenir)
      if (authNotifier.isLoading) return null;

      final isLoggedIn = authNotifier.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isCustomerPage = state.matchedLocation.startsWith('/c/');

      if (isCustomerPage) return null;
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/c/:token',
        builder: (_, state) =>
            CustomerPageScreen(token: state.pathParameters['token']!),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/customers',
            builder: (_, __) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/admin/customers/:id',
            builder: (_, state) =>
                CustomerDetailScreen(customerId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/inventory/deposits',
            builder: (_, __) => const InventoryDepositScreen(),
          ),
          GoRoute(
            path: '/admin/sales/new',
            builder: (_, __) => const NewSaleScreen(),
          ),
          GoRoute(
            path: '/admin/purchases/new',
            builder: (_, __) => const NewPurchaseScreen(),
          ),
          GoRoute(
            path: '/admin/cash/deposit',
            builder: (_, __) => const CashDepositScreen(),
          ),
          GoRoute(
            path: '/admin/cash/withdrawal',
            builder: (_, __) => const CashWithdrawalScreen(),
          ),
          GoRoute(
            path: '/admin/expenses',
            builder: (_, __) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/admin/reports/monthly',
            builder: (_, __) => const MonthlyReportScreen(),
          ),
          GoRoute(
            path: '/admin/reports/cash-flow',
            builder: (_, __) => const CashFlowReportScreen(),
          ),
          GoRoute(
            path: '/admin/reports/expense',
            builder: (_, __) => const ExpenseReportScreen(),
          ),
          GoRoute(
            path: '/admin/reports/stock',
            builder: (_, __) => const StockReportScreen(),
          ),
          GoRoute(
            path: '/admin/vault',
            builder: (_, __) => const VaultScreen(),
          ),
          GoRoute(
            path: '/admin/pistachio-types',
            builder: (_, __) => const PistachioTypesScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Sayfa bulunamadı'),
            TextButton(
              onPressed: () => state.extra,
              child: const Text('Ana sayfaya dön'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Panel'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Müşteriler'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Emanet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sell_outlined),
                selectedIcon: Icon(Icons.sell),
                label: Text('Satış'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Alım'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Kasa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Giderler'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Raporlar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.lock_outlined),
                selectedIcon: Icon(Icons.lock),
                label: Text('Kasa Emaneti'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco),
                label: Text('Fıstık Cinsleri'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Ayarlar'),
              ),
            ],
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (i) => _navigate(context, i),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ThemeToggleButton(),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/customers')) return 1;
    if (location.startsWith('/admin/inventory')) return 2;
    if (location.startsWith('/admin/sales')) return 3;
    if (location.startsWith('/admin/purchases')) return 4;
    if (location.startsWith('/admin/cash')) return 5;
    if (location.startsWith('/admin/expenses')) return 6;
    if (location.startsWith('/admin/reports')) return 7;
    if (location.startsWith('/admin/vault')) return 8;
    if (location.startsWith('/admin/pistachio-types')) return 9;
    if (location.startsWith('/admin/settings')) return 10;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    final routes = [
      '/admin/dashboard',
      '/admin/customers',
      '/admin/inventory/deposits',
      '/admin/sales/new',
      '/admin/purchases/new',
      '/admin/cash/deposit',
      '/admin/expenses',
      '/admin/reports/monthly',
      '/admin/vault',
      '/admin/pistachio-types',
      '/admin/settings',
    ];
    context.go(routes[index]);
  }
}

/// GoRouter'ın refreshListenable'ı — auth state değişimlerini GoRouter'a bildirir.
/// Bu sınıf sayesinde router yeniden yaratılmak yerine yalnızca redirect
/// fonksiyonu yeniden çalıştırılır.
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, next) {
        _authState = next;
        notifyListeners();
      },
      fireImmediately: true,
    );
  }

  AsyncValue<User?> _authState = const AsyncValue.loading();

  bool get isLoading => _authState.isLoading;
  bool get isLoggedIn => _authState.valueOrNull != null;
}

class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final extended = MediaQuery.of(context).size.width > 800;

    if (extended) {
      return SwitchListTile(
        value: isDark,
        onChanged: (_) => ref.read(themeNotifierProvider.notifier).toggle(),
        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        title: Text(isDark ? 'Karanlık' : 'Aydınlık'),
        dense: true,
      );
    }

    return IconButton(
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      tooltip: isDark ? 'Aydınlık moda geç' : 'Karanlık moda geç',
      onPressed: () => ref.read(themeNotifierProvider.notifier).toggle(),
    );
  }
}
