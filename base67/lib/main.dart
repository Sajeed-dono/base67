import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/base67_app.dart';

export 'app/base67_app.dart' show Base67App;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const Base67App());
}
