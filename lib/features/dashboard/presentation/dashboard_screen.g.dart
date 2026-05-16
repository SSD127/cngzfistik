// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customerStatsHash() => r'331330df32cf3e27585c5acd43dcef84a7c9e04a';

/// Müşteri istatistiklerini zaten açık olan stream'den hesaplar (ek Firestore isteği yok)
///
/// Copied from [customerStats].
@ProviderFor(customerStats)
final customerStatsProvider =
    AutoDisposeProvider<Map<String, dynamic>>.internal(
  customerStats,
  name: r'customerStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customerStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomerStatsRef = AutoDisposeProviderRef<Map<String, dynamic>>;
String _$recentSalesHash() => r'84ac98a82097ed855b8ad0c08f38c90e365edc8e';

/// See also [recentSales].
@ProviderFor(recentSales)
final recentSalesProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
  recentSales,
  name: r'recentSalesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recentSalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentSalesRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
