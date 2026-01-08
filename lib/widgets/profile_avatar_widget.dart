import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget to display profile avatar with caching and placeholder initials
class ProfileAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? fullName;
  final double radius;
  final BoxFit fit;

  const ProfileAvatarWidget({
    super.key,
    this.avatarUrl,
    this.fullName,
    this.radius = 30,
    this.fit = BoxFit.cover,
  });

  String _getInitials() {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      // Show placeholder with initials
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Show cached network image with fallback
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: fit,
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
            child: Text(
              _getInitials(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
            child: Text(
              _getInitials(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

