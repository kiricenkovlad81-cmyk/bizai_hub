import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'theme.dart';
import 'ui/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState()..boot();
  runApp(BizAiApp(state: state));
}

class BizAiApp extends StatelessWidget {
  const BizAiApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: state.themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'BizAI Hub',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          home: const Shell(),
        ),
      ),
    );
  }
}
