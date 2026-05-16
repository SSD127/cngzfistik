// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_page_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customerPageDataHash() => r'bed9244c41a2caf161a65d4dc9fd93fe117f4e5c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [customerPageData].
@ProviderFor(customerPageData)
const customerPageDataProvider = CustomerPageDataFamily();

/// See also [customerPageData].
class CustomerPageDataFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [customerPageData].
  const CustomerPageDataFamily();

  /// See also [customerPageData].
  CustomerPageDataProvider call(
    String token,
  ) {
    return CustomerPageDataProvider(
      token,
    );
  }

  @override
  CustomerPageDataProvider getProviderOverride(
    covariant CustomerPageDataProvider provider,
  ) {
    return call(
      provider.token,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'customerPageDataProvider';
}

/// See also [customerPageData].
class CustomerPageDataProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [customerPageData].
  CustomerPageDataProvider(
    String token,
  ) : this._internal(
          (ref) => customerPageData(
            ref as CustomerPageDataRef,
            token,
          ),
          from: customerPageDataProvider,
          name: r'customerPageDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$customerPageDataHash,
          dependencies: CustomerPageDataFamily._dependencies,
          allTransitiveDependencies:
              CustomerPageDataFamily._allTransitiveDependencies,
          token: token,
        );

  CustomerPageDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(CustomerPageDataRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomerPageDataProvider._internal(
        (ref) => create(ref as CustomerPageDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _CustomerPageDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerPageDataProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CustomerPageDataRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `token` of this provider.
  String get token;
}

class _CustomerPageDataProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with CustomerPageDataRef {
  _CustomerPageDataProviderElement(super.provider);

  @override
  String get token => (origin as CustomerPageDataProvider).token;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
