import 'package:flutter/widgets.dart';

/// A plain cross-fade route, used when leaving the splash screen.
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 700),
    super.settings,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
             child: child,
           );
         },
       );
}
