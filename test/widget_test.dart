import 'package:fitplan/app.dart';
import 'package:fitplan/models/profile.dart';
import 'package:fitplan/services/auth_service.dart';
import 'package:fitplan/services/storage.dart';
import 'package:fitplan/state/app_state.dart';
import 'package:fitplan/ui/home_shell.dart';
import 'package:fitplan/ui/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppState> _state() async {
  final store = MemoryStore();
  final state = AppState(
    store: store,
    auth: LocalAuthService(store, iterations: 1000),
    clock: () => DateTime(2026, 10, 13, 9),
  );
  await state.init();
  return state;
}

void main() {
  testWidgets('register → onboarding → generated programs', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = await _state();
    await tester.pumpWidget(FitPlanApp(state: state));
    await tester.pumpAndSettle();

    // Auth page.
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    await tester.tap(find.text('สมัครสมาชิก'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ต้น');
    await tester.enterText(fields.at(1), 'ton@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');
    await tester.tap(find.text('สร้างบัญชี'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // Onboarding step 1.
    expect(find.byType(OnboardingPage), findsOneWidget);
    final body = find.byType(TextFormField);
    await tester.enterText(body.at(1), '28');
    await tester.enterText(body.at(2), '72');
    await tester.enterText(body.at(3), '172');
    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();

    // Step 2.
    await tester.tap(find.text('6 เดือน – 2 ปี'));
    await tester.tap(find.text('เพิ่มกล้ามเนื้อ'));
    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();

    // Step 3 keeps defaults (3 days, 60 min, Full Gym).
    await tester.tap(find.text('จัดโปรแกรมให้ฉัน'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(state.profile!.experience, Experience.sixTo24Months);
    expect(state.generatedPrograms.length, 3);
    expect(find.text('จัดให้จากข้อมูลของคุณ'), findsOneWidget);
    expect(find.textContaining('Full Gym · Full Body'), findsWidgets);
  });

  testWidgets('wide screens use a navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await _state();
    await state.register('ต้น', 'ton@example.com', 'password123');
    await state.saveProfile(const UserProfile(
      name: 'ต้น',
      sex: Sex.male,
      age: 28,
      weightKg: 72,
      heightCm: 172,
      experience: Experience.twoToFiveYears,
      goal: Goal.strength,
      daysPerWeek: 3,
      sessionMinutes: 75,
      preferredGym: GymType.full,
    ));
    await tester.pumpWidget(FitPlanApp(state: state));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('สวัสดี ต้น'), findsOneWidget);
    expect(find.text('เริ่มเวิร์กเอาต์'), findsNothing); // Tuesday is rest
  });
}
