// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customerRepositoryHash() =>
    r'234158c467c532f11ab2113d34a632ff39d8447c';

/// See also [customerRepository].
@ProviderFor(customerRepository)
final customerRepositoryProvider = Provider<CustomerRepository>.internal(
  customerRepository,
  name: r'customerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomerRepositoryRef = ProviderRef<CustomerRepository>;
String _$customersStreamHash() => r'0acaeadc8f01509d987aae85e62d81078a1f3a25';

/// See also [customersStream].
@ProviderFor(customersStream)
final customersStreamProvider = StreamProvider<List<CustomerModel>>.internal(
  customersStream,
  name: r'customersStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customersStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomersStreamRef = StreamProviderRef<List<CustomerModel>>;
String _$customerByIdHash() => r'fbb24bd0b4151dc3b54b6a20cfce2fe533bf4643';

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

/// See also [customerById].
@ProviderFor(customerById)
const customerByIdProvider = CustomerByIdFamily();

/// See also [customerById].
class CustomerByIdFamily extends Family<AsyncValue<CustomerModel?>> {
  /// See also [customerById].
  const CustomerByIdFamily();

  /// See also [customerById].
  CustomerByIdProvider call(
    String id,
  ) {
    return CustomerByIdProvider(
      id,
    );
  }

  @override
  CustomerByIdProvider getProviderOverride(
    covariant CustomerByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'customerByIdProvider';
}

/// See also [customerById].
class CustomerByIdProvider extends AutoDisposeFutureProvider<CustomerModel?> {
  /// See also [customerById].
  CustomerByIdProvider(
    String id,
  ) : this._internal(
          (ref) => customerById(
            ref as CustomerByIdRef,
            id,
          ),
          from: customerByIdProvider,
          name: r'customerByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$customerByIdHash,
          dependencies: CustomerByIdFamily._dependencies,
          allTransitiveDependencies:
              CustomerByIdFamily._allTransitiveDependencies,
          id: id,
        );

  CustomerByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<CustomerModel?> Function(CustomerByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomerByIdProvider._internal(
        (ref) => create(ref as CustomerByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CustomerModel?> createElement() {
    return _CustomerByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CustomerByIdRef on AutoDisposeFutureProviderRef<CustomerModel?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _CustomerByIdProviderElement
    extends AutoDisposeFutureProviderElement<CustomerModel?>
    with CustomerByIdRef {
  _CustomerByIdProviderElement(super.provider);

  @override
  String get id => (origin as CustomerByIdProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
