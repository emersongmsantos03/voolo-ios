import 'package:flutter/material.dart';
import 'package:jetx/core/ui/responsive.dart';
import 'package:jetx/widgets/app_drawer.dart';

class WebLayoutWrapper extends StatelessWidget {
  final Widget child;
  final String? routeName;

  const WebLayoutWrapper({
    super.key,
    required this.child,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.width(context) >= 1024;

    if (!isWide) {
      return child;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            width: 270,
            child: AppDrawer(isWebSidebar: true),
          ),
          Expanded(
            child: ClipRect(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

