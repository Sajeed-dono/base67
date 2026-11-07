import 'package:flutter/material.dart';

import '../ui/theme.dart';
import 'game_router.dart';

class Base67App extends StatelessWidget {
  const Base67App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BASE 67',
    theme: Base67Theme.light(),
    home: const GameBootstrap(),
  );
}
