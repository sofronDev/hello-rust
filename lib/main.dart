import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/storage.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await PrefsStore.open();
  final state = AppState(store: store, auth: LocalAuthService(store));
  await state.init();
  runApp(FitPlanApp(state: state));
}
