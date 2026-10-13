import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/auth_page.dart';
import 'ui/home_shell.dart';
import 'ui/onboarding_page.dart';
import 'ui/theme.dart';

class FitPlanApp extends StatelessWidget {
  const FitPlanApp({super.key, required this.state});

  final AppState state;

  static final _light = buildTheme(Brightness.light);
  static final _dark = buildTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'FitPlan — บันทึกการออกกำลังกาย',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: state.themeMode,
          locale: const Locale('th'),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const RootGate(),
        ),
      ),
    );
  }
}

/// Chooses login → profile setup → main app based on state.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final Widget child;
    if (!state.ready) {
      child = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (!state.loggedIn) {
      child = const AuthPage();
    } else if (state.profile == null) {
      child = const OnboardingPage();
    } else {
      child = const HomeShell();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}
