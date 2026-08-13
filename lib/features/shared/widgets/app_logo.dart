import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80.0,
    this.padding = 0.0,
  });

  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.science,
                size: size * 0.5,
                color: scheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({
    super.key,
    this.subtitle = 'Beranda',
    this.showLogo = true,
  });

  final String subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          const AppLogo(size: 32),
          const SizedBox(width: 12),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lapor Lab',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1.1,
              ),
            ),
            Text(
              subtitle.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
