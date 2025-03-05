import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onWillPop;

  const BasePage({
    Key? key,
    required this.child,
    this.onWillPop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log device info in debug mode
    if (kDebugMode) {
      print('Device: ${defaultTargetPlatform.toString()}');
      print('Manufacturer: ${Theme.of(context).platform.toString()}');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (kDebugMode) {
          print('Back gesture/button triggered');
        }

        if (didPop) {
          return;
        }

        if (onWillPop != null) {
          final shouldPop = await onWillPop!();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
          return;
        }

        final canPop = Navigator.canPop(context);
        if (canPop && context.mounted) {
          Navigator.pop(context);
        }
        return;
      },
      child: child,
    );
  }
}
