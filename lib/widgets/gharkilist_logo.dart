import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/localization_service.dart';

class GharkiListLogoWidget extends StatelessWidget {
  final double fontSize;
  final double iconSize;
  final AppLanguage? language;

  const GharkiListLogoWidget({
    super.key,
    this.fontSize = 22,
    this.iconSize = 28,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gharkiColor = isDark ? Colors.white : const Color(0xFF1E293B);

    AppLanguage currentLang = language ?? AppLanguage.english;
    try {
      final settings = context.watch<AppSettingsProvider>();
      currentLang = language ?? settings.language;
    } catch (_) {}

    final isHindi = currentLang == AppLanguage.hindi;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/logo.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: isHindi ? 'घरकी' : 'gharki',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: gharkiColor,
                  letterSpacing: isHindi ? 0 : -0.5,
                ),
              ),
              TextSpan(
                text: isHindi ? 'लिस्ट' : 'list',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00C853),
                  letterSpacing: isHindi ? 0 : -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
