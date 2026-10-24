import 'package:flutter/material.dart';

/// CircleAvatar that shows a network image when [url] is non-null, or an
/// initials/icon fallback otherwise.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    required this.radius,
    this.url,
    this.initials,
    this.fallbackIcon = Icons.person,
    super.key,
  });

  final double radius;
  final String? url;

  /// One or two letters to show when [url] is null. Falls back to [fallbackIcon].
  final String? initials;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final text = initials?.isNotEmpty == true ? initials! : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFCCFF00),
      foregroundColor: Colors.black,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? (text != null
                ? Text(
                    text,
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(fallbackIcon, size: radius))
          : null,
    );
  }
}
