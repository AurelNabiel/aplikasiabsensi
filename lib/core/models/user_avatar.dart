import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatar: tampilkan foto profil bila ada, jika tidak pakai inisial nama.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 24,
  });

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    final initial = (name.trim().isNotEmpty ? name.trim()[0] : '?').toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasUrl ? NetworkImage(url!) : null,
      child: hasUrl
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}

/// Logo divisi (aset) berbentuk lingkaran, dengan fallback ikon.
class DivisionLogo extends StatelessWidget {
  const DivisionLogo({super.key, required this.asset, this.size = 28});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.groups_2_rounded, size: size, color: AppColors.primary),
      ),
    );
  }
}
