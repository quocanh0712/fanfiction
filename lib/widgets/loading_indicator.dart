import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: color ?? const Color(0xFF7d26cd),
      size: size ?? 50.0,
    );
  }
}
