import 'package:flutter/material.dart';

import 'bordered_icon_button.dart';

class CommonSliverAppBar extends StatelessWidget {
  final String title;
  final bool hasLeading;

  const CommonSliverAppBar({
    super.key,
    required this.title,
    this.hasLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      backgroundColor:
          theme.appBarTheme.backgroundColor ?? theme.colorScheme.background,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      floating: true,
      snap: true,
      leading: hasLeading
          ? BorderedIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
              margin: const EdgeInsets.only(left: 16.0),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onBackground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
