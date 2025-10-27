import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget {
  final String? leftIconPath;
  final String title;
  final Widget? rightAction;
  final bool? isHaveIcon;
  final VoidCallback? onLeftIconTap;
  final VoidCallback? onTitleTap;
  final VoidCallback? onRightActionTap;

  const AppHeader({
    super.key,
    this.leftIconPath = "assets/icons/ic_header_robot.svg",
    this.title = 'Storedo',
    this.rightAction,
    this.onLeftIconTap,
    this.onTitleTap,
    this.onRightActionTap,
    this.isHaveIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 55),
        const Divider(color: Colors.white24, height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildLeftIcon(), _buildTitle(), _buildRightAction()],
          ),
        ),
        const Divider(color: Colors.white24, height: 12),
      ],
    );
  }

  Widget _buildLeftIcon() {
    if (leftIconPath == null) {
      return const SizedBox(width: 20, height: 20);
    }

    final iconWidget = SizedBox(
      width: 20,
      height: 20,
      child: SvgPicture.asset(leftIconPath!, width: 20, height: 20),
    );

    return onLeftIconTap != null
        ? GestureDetector(onTap: onLeftIconTap, child: iconWidget)
        : iconWidget;
  }

  Widget _buildTitle() {
    final titleWidget = Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    return onTitleTap != null
        ? GestureDetector(onTap: onTitleTap, child: titleWidget)
        : titleWidget;
  }

  Widget _buildRightAction() {
    if (rightAction != null) {
      return onRightActionTap != null
          ? GestureDetector(onTap: onRightActionTap, child: rightAction!)
          : rightAction!;
    }

    return isHaveIcon == false
        ? const SizedBox(width: 20)
        : const Icon(Icons.search, size: 20, color: Colors.white);
  }
}
