import 'package:flutter/material.dart';

class StokEasyLogo extends StatelessWidget {
  const StokEasyLogo({super.key, this.size = 24, this.fit = BoxFit.contain});

  static const String assetPath = 'assets/images/stokeasy-png.png';

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}

class StokEasyLogoBadge extends StatelessWidget {
  const StokEasyLogoBadge({
    super.key,
    this.size = 24,
    this.padding = const EdgeInsets.all(3),
    this.backgroundColor = const Color(0xFFFCA311),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double size;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding,
        child: const FittedBox(fit: BoxFit.contain, child: StokEasyLogo()),
      ),
    );
  }
}
