import 'package:flutter/material.dart';
import 'app_config.dart';

/// Виджет-баннер окружения.
/// В DEV-режиме оборачивает приложение в [Banner] с меткой «DEV».
/// В PROD ничего не показывает.
class EnvBanner extends StatelessWidget {
  final Widget child;
  const EnvBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.instance.isProd) return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: AppConfig.instance.environment.name.toUpperCase(),
        location: BannerLocation.topStart,
        color: Colors.deepOrange,
        child: child,
      ),
    );
  }
}
