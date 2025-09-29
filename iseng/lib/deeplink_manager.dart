import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:app_links/app_links.dart';
import 'package:iseng/main.dart';
import 'route_observer.dart';

class DeepLinkManager {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  // ===== DEDUPE STATE (2 detik) =====
  Uri? _lastUri;
  DateTime? _lastAt;

  Future<void> start() async {
    // Tunda 1 frame supaya Navigator sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) _handle(initial);
      } catch (e) {
        debugPrint('getInitialAppLink error: $e');
      }

      _sub = _appLinks.uriLinkStream.listen(
        (uri) => _handle(uri),
        onError: (e) => debugPrint('uriLinkStream error: $e'),
      );
    });
  }

  void _handle(Uri uri) {
    debugPrint('🔗 deeplink: $uri');

    // ====== DEDUPE 2 DETIK (SUPAYA GA DOUBLE) ======
    final now = DateTime.now();
    if (_lastUri?.toString() == uri.toString() &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastUri = uri;
    _lastAt = now;

    final nav = navKey.currentState;
    if (nav == null) {
      // Navigator belum siap → coba lagi di frame berikutnya
      WidgetsBinding.instance.addPostFrameCallback((_) => _handle(uri));
      return;
    }

    _routeUri(nav, uri);
  }

  void _routeUri(NavigatorState nav, Uri uri) {
    final path = uri.path; // contoh: '/', '/2', '/3'

    switch (path) {
      case '/2':
        debugPrint('navigasi ke Page 2 mungkin ada locgic2 dulu');
        _goHomeThen(nav, page: '/2');
        break;
      case '/3':
        _goHomeThen(nav, page: '/3');
        break;
      case '/product':
        final id = uri.queryParameters['id'];
        final ref = uri.queryParameters['ref'];
        if (id != null) {
          debugPrint('MANAGER ke ProductPage id=$id ref=$ref');
          _goHomeThen(
            nav,
            page: '/product',
            args: ProductArgs(id: id, ref: ref), // atau Map
          );
        }
        break;

      default:
        _goHomeThen(nav, page: '/'); // normalize ke Home saja
        break;
    }
  }

  // ====== 3 ATURAN: home dulu / push / do nothing ======
  void _goHomeThen(NavigatorState nav, {String? page, Object? args}) {
    final current = CurrentRoute.name; // '/', '/2', '/3', dst.

    // 3) Kalau SUDAH di target → do nothing
    if (page != null && current == page) return;

    // 2) Kalau SUDAH di Home → hanya push target (kalau ada)
    if (current == '/' || current == null) {
      if (page != null && page != '/') nav.pushNamed(page, arguments: args);
      return;
    }

    // 1) Kalau BUKAN di Home → reset stack ke Home dulu, lalu push target
    nav.pushNamedAndRemoveUntil('/', (r) => false);
    if (page != null && page != '/') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav.pushNamed(page, arguments: args);
      });
    }
  }

  void dispose() => _sub?.cancel();
}

class ProductArgs {
  final String id;
  final String? ref;
  const ProductArgs({required this.id, this.ref});
}
