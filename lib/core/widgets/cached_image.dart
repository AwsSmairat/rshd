import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for remote pictures (subject covers, announcement banners).
///
/// A picture is downloaded once and then read from the device on every later
/// launch. Server files are stored under unique names, so a changed picture
/// arrives under a new URL and is fetched then; an unchanged one is also
/// re-checked with the server after [_stalePeriod].
class AppImageCache {
  AppImageCache._();

  static const _key = 'rshd_images';
  static const _stalePeriod = Duration(days: 30);

  static final CacheManager instance = CacheManager(
    Config(_key, stalePeriod: _stalePeriod, maxNrOfCacheObjects: 400),
  );

  /// Drops every cached picture, e.g. when the user signs out.
  static Future<void> clear() => instance.emptyCache();
}

/// Drop-in for `NetworkImage(url)` that goes through [AppImageCache].
ImageProvider cachedImage(String url) =>
    CachedNetworkImageProvider(url, cacheManager: AppImageCache.instance);
