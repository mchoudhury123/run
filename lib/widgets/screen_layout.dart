import 'package:flutter/material.dart';

class ScreenLayout extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool useSafeArea;
  final EdgeInsets? padding;
  final bool centerContent;

  const ScreenLayout({
    super.key,
    required this.child,
    this.backgroundColor,
    this.useSafeArea = true,
    this.padding,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: size.width * 0.05,
      vertical: size.height * 0.02,
    );

    Widget content = Container(
      width: size.width,
      height: size.height,
      padding: padding ?? defaultPadding,
      child: centerContent ? Center(child: child) : child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: content,
    );
  }
} 