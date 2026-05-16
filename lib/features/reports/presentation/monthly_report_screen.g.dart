// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_report_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyReportHash() => r'019de6b79713861d00c3444f96a0b80d33de9c6e';

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

/// See also [monthlyReport].
@ProviderFor(monthlyReport)
const monthlyReportProvider = MonthlyReportFamily();

/// See also [monthlyReport].
class MonthlyReportFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [monthlyReport].
  const MonthlyReportFamily();

  /// See also [monthlyReport].
  MonthlyReportProvider call(
    int year,
    int month,
  ) {
    return MonthlyReportProvider(
      year,
      month,
    );
  }

  @override
  MonthlyReportProvider getProviderOverride(
    covariant MonthlyReportProvider provider,
  ) {
    return call(
      provider.year,
      provider.month,
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
  String? get name => r'monthlyReportProvider';
}

/// See also [monthlyReport].
class MonthlyReportProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [monthlyReport].
  MonthlyReportProvider(
    int year,
    int month,
  ) : this._internal(
          (ref) => monthlyReport(
            ref as MonthlyReportRef,
            year,
            month,
          ),
          from: monthlyReportProvider,
          name: r'monthlyReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyReportHash,
          dependencies: MonthlyReportFamily._dependencies,
          allTransitiveDependencies:
              MonthlyReportFamily._allTransitiveDependencies,
          year: year,
          month: month,
        );

  MonthlyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(MonthlyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyReportProvider._internal(
        (ref) => create(ref as MonthlyReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _MonthlyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyReportProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyReportRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _MonthlyReportProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with MonthlyReportRef {
  _MonthlyReportProviderElement(super.provider);

  @override
  int get year => (origin as MonthlyReportProvider).year;
  @override
  int get month => (origin as MonthlyReportProvider).month;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
