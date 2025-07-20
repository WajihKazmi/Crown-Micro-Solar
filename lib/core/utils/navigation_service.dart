import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigator!.pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    Route<T> newRoute,
    RoutePredicate predicate,
  ) {
    return navigator!.pushAndRemoveUntil<T>(newRoute, predicate);
  }

  static void pop<T extends Object?>([T? result]) {
    return navigator!.pop<T>(result);
  }

  static bool canPop() {
    return navigator!.canPop();
  }

  static void popUntil(RoutePredicate predicate) {
    navigator!.popUntil(predicate);
  }
} 