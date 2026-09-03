import 'package:flutter/material.dart';
import '../models/access_level.dart';

class AccessLevelBadge extends StatelessWidget {
  final int level;
  const AccessLevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final al = AccessLevel.fromInt(level);
    final Color color;
    switch (al) {
      case AccessLevel.admin:
        color = Colors.deepPurple;
        break;
      case AccessLevel.manageItems:
        color = Colors.blue;
        break;
      case AccessLevel.viewCheck:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(
        al.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
