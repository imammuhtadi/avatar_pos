// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productsStreamHash() => r'2b8de5501eb79deef123c7a47237f1b6b3d40a86';

/// Provider for realtime product updates
///
/// Copied from [productsStream].
@ProviderFor(productsStream)
final productsStreamProvider =
    AutoDisposeStreamProvider<List<Product>>.internal(
      productsStream,
      name: r'productsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductsStreamRef = AutoDisposeStreamProviderRef<List<Product>>;
String _$productsHash() => r'8500e31d80fc37c68b62fdf6b72c6e01c472ef6a';

/// Products provider - manages product list state with Supabase
///
/// Copied from [Products].
@ProviderFor(Products)
final productsProvider =
    AutoDisposeAsyncNotifierProvider<Products, List<Product>>.internal(
      Products.new,
      name: r'productsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Products = AutoDisposeAsyncNotifier<List<Product>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
