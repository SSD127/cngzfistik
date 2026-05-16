// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_report_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cashFlowReportHash() => r'7b5aaddba4de2fe79057672c3daad7f05a5f86b0';

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

/// See also [cashFlowReport].
@ProviderFor(cashFlowReport)
const cashFlowReportProvider = CashFlowReportFamily();

/// See also [cashFlowReport].
class CashFlowReportFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [cashFlowReport].
  const CashFlowReportFamily();

  /// See also [cashFlowReport].
  CashFlowReportProvider call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return CashFlowReportProvider(
      startDate,
      endDate,
    );
  }

  @override
  CashFlowReportProvider getProviderOverride(
    covariant CashFlowReportProvider provider,
  ) {
    return call(
      provider.startDate,
      provider.endDate,
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
  String? get name => r'cashFlowReportProvider';
}

/// See also [cashFlowReport].
class CashFlowReportProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [cashFlowReport].
  CashFlowReportProvider(
    DateTime startDate,
    DateTime endDate,
  ) : this._internal(
          (ref) => cashFlowReport(
            ref as CashFlowReportRef,
            startDate,
            endDate,
          ),
          from: cashFlowReportProvider,
          name: r'cashFlowReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cashFlowReportHash,
          dependencies: CashFlowReportFamily._dependencies,
          allTransitiveDependencies:
              CashFlowReportFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
        );

  CashFlowReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(CashFlowReportRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CashFlowReportProvider._internal(
        (ref) => create(ref as CashFlowReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _CashFlowReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CashFlowReportProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CashFlowReportRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _CashFlowReportProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with CashFlowReportRef {
  _CashFlowReportProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as CashFlowReportProvider).startDate;
  @override
  DateTime get endDate => (origin as CashFlowReportProvider).endDate;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
