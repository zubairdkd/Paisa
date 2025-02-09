import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaisaAnnotatedRegionWidget extends StatelessWidget {
  const PaisaAnnotatedRegionWidget({
    super.key,
    required this.child,
    this.color,
  });
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Color navColor = ElevationOverlay.applySurfaceTint(
      Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.surfaceTint,
      1,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarContrastEnforced: true,
        systemNavigationBarColor: color ?? navColor,
        systemNavigationBarDividerColor: color ?? navColor,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
      ),
      child: child,
    );
  }
}
