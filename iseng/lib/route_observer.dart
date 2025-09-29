// route_observer.dart
import 'package:flutter/widgets.dart';

final routeObserver = RouteObserver<PageRoute<dynamic>>();

class CurrentRoute {
  static String? name;
}

class RouteTracker extends RouteObserver<PageRoute<dynamic>> {
  void _set(Route<dynamic>? r) {
    final n = r?.settings.name;
    if (n != null) CurrentRoute.name = n;
  }
  @override
  void didPush(Route route, Route? previousRoute) => _set(route);
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _set(newRoute);
  @override
  void didPop(Route route, Route? previousRoute) => _set(previousRoute);
}

final routeTracker = RouteTracker();
