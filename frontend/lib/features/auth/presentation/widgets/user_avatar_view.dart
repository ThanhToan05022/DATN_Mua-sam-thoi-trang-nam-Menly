import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class UserAvatarView extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final double size;
  final bool showBorder;

  const UserAvatarView({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    this.size = 80,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final commaIdx = url.indexOf(',');
          final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
          final bytes = base64Decode(base64Str);
          content = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          content = _buildInitial();
        }
      } else {
        content = ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (ctx, _) => Container(
              color: AppTheme.surface2,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            errorWidget: (ctx, _, __) => _buildInitial(),
          ),
        );
      }
    } else {
      content = _buildInitial();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (url == null || url.isEmpty)
            ? const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
        border: showBorder ? Border.all(color: AppTheme.surface2, width: 2) : null,
      ),
      child: content,
    );
  }

  Widget _buildInitial() {
    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
